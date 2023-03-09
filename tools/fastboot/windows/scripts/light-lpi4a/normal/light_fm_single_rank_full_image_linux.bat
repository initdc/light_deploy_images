:: Script to flash imagess via fastboot

@echo off
call:RunACmd "..\..\..\fastboot.exe flash ram ..\..\..\..\..\..\images\light-lpi4a\light_fastboot_image_single_rank\u-boot-with-spl.bin"
call:RunACmd "..\..\..\fastboot.exe reboot"
ping 127.0.0.1 -n 5 >nul
call:RunACmd "..\..\..\fastboot.exe flash uboot  ..\..\..\..\..\..\images\light-lpi4a\light_fastboot_image_single_rank\u-boot-with-spl.bin"
call:RunACmd "..\..\..\fastboot.exe flash boot  ..\..\..\..\..\..\images\light-lpi4a\boot.ext4"
call:RunACmd "..\..\..\fastboot.exe flash root  ..\..\..\..\..\..\images\light-lpi4a\rootfs.thead-image-linux.ext4"

pause
exit

:RunACmd
SETLOCAL
set CmdStr=%1
echo IIIIIIIIIIIIIIII Run Cmd:  %CmdStr% 
%CmdStr:~1,-1% || goto RunACmd

GOTO:EOF
