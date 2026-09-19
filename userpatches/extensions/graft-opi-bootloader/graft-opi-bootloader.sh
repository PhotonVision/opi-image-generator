#!/bin/bash

# Replace the raw sectors between the GPT and the first partition with the
# bootloader from a matching ubuntu-rockchip reference image.
#
# Armbian's U-Boot SPL/proper live in those sectors and chain-load from
# SD/eMMC, which breaks SPI U-Boot boot. The workflow downloads a known working
# ubuntu-rockchip image into this directory as bootloader.img.xz; this hook grafts its
# idbloader and U-Boot proper into the sector range the old
# zero-opi-bootloader extension used to zero.
function post_build_image__graft_bootloader_section() {
    local image="${FINAL_IMAGE_FILE}"
    local gpt_sectors=64
    local ext_dir reference
    ext_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    reference="${ext_dir}/bootloader.img.xz"

    if [[ ! -f "${reference}" ]]; then
        echo "Reference bootloader image not found: ${reference}"
        exit 1
    fi

    # Find partition geometry programmatically - offsets vary between images
    local json sector_size part_start count
    json="$(sfdisk -J "${image}")"
    sector_size="$(jq -r '.partitiontable.sectorsize // 512' <<<"${json}")"
    part_start="$(jq -r '[.partitiontable.partitions[].start] | min' <<<"${json}")"
    count=$((part_start - gpt_sectors))

    if [[ "${count}" -le 0 ]]; then
        echo "Refusing to graft: partition 1 starts at sector ${part_start} (sector size ${sector_size})"
        exit 1
    fi

    echo "Partition 1 starts at sector ${part_start} (sector size ${sector_size}B); grafting sectors ${gpt_sectors}-$((part_start - 1)) (${count} sectors) from $(basename "${reference}")"

    # Only the head of the reference is needed (idbloader at sector 64,
    # U-Boot proper at 8 MiB), so decompress just the first blocks of the
    # stream. xz dies of SIGPIPE once dd has enough data; the size check
    # below catches a truncated stream.
    local tmp expected
    tmp="$(mktemp)"
    expected=$(( (gpt_sectors + count) * sector_size ))
    xz -dc "${reference}" 2>/dev/null | dd of="${tmp}" bs="${sector_size}" count=$((gpt_sectors + count)) iflag=fullblock status=none

    if [[ "$(stat -c%s "${tmp}")" -ne "${expected}" ]]; then
        echo "Reference image too small: got $(stat -c%s "${tmp}") bytes, expected ${expected}"
        rm -f "${tmp}"
        exit 1
    fi

    # Sanity-check the source geometry by parsing the GPT header and entries
    # directly: sfdisk cannot read a truncated image, and only the head was
    # extracted. Fail closed unless the reference is a 512-byte-sector GPT
    # image whose partition entry array lies fully inside the first 64
    # sectors. Never copy partition data into the bootloader region.
    if [[ "${sector_size}" -ne 512 ]]; then
        echo "Unsupported target sector size ${sector_size}; only 512-byte sectors are supported"
        rm -f "${tmp}"
        exit 1
    fi

    local sig entries_lba num_entries entry_size
    sig="$(dd if="${tmp}" bs=512 skip=1 count=1 status=none | head -c 8)"
    if [[ "${sig}" != "EFI PART" ]]; then
        echo "Reference image has no GPT header at LBA 1; refusing to graft from a non-GPT image"
        rm -f "${tmp}"
        exit 1
    fi
    entries_lba="$(dd if="${tmp}" bs=512 skip=1 count=1 status=none | od -An -j 72 -N 8 -tu8 | tr -d ' ')"
    num_entries="$(dd if="${tmp}" bs=512 skip=1 count=1 status=none | od -An -j 80 -N 4 -tu4 | tr -d ' ')"
    entry_size="$(dd if="${tmp}" bs=512 skip=1 count=1 status=none | od -An -j 84 -N 4 -tu4 | tr -d ' ')"
    if [[ "${entry_size}" -lt 40 || "${num_entries}" -lt 1 \
        || $(( entries_lba + (num_entries * entry_size + 511) / 512 )) -gt "${gpt_sectors}" ]]; then
        echo "Reference GPT partition entries do not fit in the first ${gpt_sectors} sectors (lba=${entries_lba}, count=${num_entries}, size=${entry_size}); cannot verify source geometry"
        rm -f "${tmp}"
        exit 1
    fi

    local src_part_start=0 i off hex start
    for ((i = 0; i < num_entries; i++)); do
        off=$(( entries_lba * 512 + i * entry_size ))
        hex="$(od -An -j "${off}" -N 16 -tx1 "${tmp}" | tr -d ' \n')"
        if [[ -n "${hex//0/}" ]]; then
            start="$(od -An -j $((off + 32)) -N 8 -tu8 "${tmp}" | tr -d ' ')"
            if [[ "${src_part_start}" -eq 0 || "${start}" -lt "${src_part_start}" ]]; then
                src_part_start="${start}"
            fi
        fi
    done
    if [[ "${src_part_start}" -eq 0 ]]; then
        echo "Reference GPT has no partitions; refusing to graft"
        rm -f "${tmp}"
        exit 1
    fi
    if [[ "${src_part_start}" -lt $((gpt_sectors + count)) ]]; then
        echo "Reference partition 1 starts at sector ${src_part_start}, before sector $((gpt_sectors + count)); refusing to copy partition data into the bootloader region"
        rm -f "${tmp}"
        exit 1
    fi

    dd if="${tmp}" of="${image}" bs="${sector_size}" skip="${gpt_sectors}" seek="${gpt_sectors}" count="${count}" conv=notrunc status=none
    rm -f "${tmp}"
    sync
}
