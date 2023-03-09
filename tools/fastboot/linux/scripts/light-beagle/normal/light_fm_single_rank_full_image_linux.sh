#! /bin/sh
# Script to flash imagess via fastboot
#


sudo ../../../fastboot flash ram ../../../../../../images/light-beagle/light_fastboot_image_single_rank/u-boot-with-spl.bin
sudo ../../../fastboot reboot
sleep 10
sudo ../../../fastboot flash uboot ../../../../../../images/light-beagle/light_fastboot_image_single_rank/u-boot-with-spl.bin
sudo ../../../fastboot flash boot ../../../../../../images/light-beagle/boot.ext4
sudo ../../../fastboot flash root ../../../../../../images/light-beagle/rootfs.light-fm-image.ext4
