#! /bin/sh
# Script to flash imagess via fastboot
#


sudo ../../../fastboot flash ram ../../../../../../images/light-lpi4a/light_fastboot_image_single_rank/u-boot-with-spl.bin
sudo ../../../fastboot reboot
sleep 10
sudo ../../../fastboot flash uboot ../../../../../../images/light-lpi4a/light_fastboot_image_single_rank/u-boot-with-spl.bin
sudo ../../../fastboot flash boot ../../../../../../images/light-lpi4a/boot.ext4
sudo ../../../fastboot flash root ../../../../../../images/light-lpi4a/rootfs.thead-image-multimedia.ext4