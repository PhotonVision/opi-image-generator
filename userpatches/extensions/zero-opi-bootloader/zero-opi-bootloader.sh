#!/bin/bash

# Zero the raw sectors between the GPT and the first partition.
#
# U-Boot SPL + U-Boot proper live in those sectors; zeroing them makes the
# board's SPI U-Boot boot the kernel directly instead of chain-loading and
# failing. Logic migrated from photon-image-modifier's main.yml workflow.
function post_build_image__zero_bootloader_section() {
    local image="${FINAL_IMAGE_FILE}"

    # Find partition geometry programmatically - offsets vary between images
    local json sector_size part_start gpt_sectors count
    json="$(sfdisk -J "${image}")"
    sector_size="$(jq -r '.partitiontable.sectorsize // 512' <<<"${json}")"
    part_start="$(jq -r '[.partitiontable.partitions[].start] | min' <<<"${json}")"

    # Keep the first 64 sectors (protective MBR + GPT header + entries).
    gpt_sectors=64
    count=$((part_start - gpt_sectors))

    if [[ "${count}" -le 0 ]]; then
        echo "Refusing to zero: partition 1 starts at sector ${part_start} (sector size ${sector_size})"
        exit 1
    fi

    echo "Partition 1 starts at sector ${part_start} (sector size ${sector_size}B); zeroing sectors ${gpt_sectors}-$((part_start - 1)) (${count} sectors)"
    dd if=/dev/zero of="${image}" bs="${sector_size}" seek="${gpt_sectors}" count="${count}" conv=notrunc
    sync
}
