#! /bin/sh
# Script to flash imagess via fastboot
#


sudo ../../../fastboot flash ram ../../../../../../images/light-a-val/light_fastboot_image_single_rank/u-boot-with-spl.bin
sudo ../../../fastboot reboot
sleep 10
sudo ../../../fastboot flash uboot ../../../../../../images/light-a-val/light_fastboot_image_single_rank/u-boot-with-spl.bin
sudo ../../../fastboot flash boot ../../../../../../images/light-a-val/boot.ext4
sudo ../../../fastboot flash root ../../../../../../images/light-a-val/rootfs.thead-image-linux.ext4