#! /bin/sh
# Script to flash imagess via fastboot
#


sudo ../../../fastboot flash ram ../../../../../../images/light-b-product/light_fastboot_image_single_rank/u-boot-with-spl.bin
sudo ../../../fastboot reboot
sleep 10
sudo ../../../fastboot flash uboot ../../../../../../images/light-b-product/light_fastboot_image_single_rank/u-boot-with-spl.bin
sudo ../../../fastboot flash boot ../../../../../../images/light-b-product/boot.ext4
sudo ../../../fastboot flash root ../../../../../../images/light-b-product/rootfs.thead-image-gui.ext4