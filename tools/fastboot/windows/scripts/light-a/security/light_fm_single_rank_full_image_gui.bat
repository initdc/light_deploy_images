:: Script to flash images via fastboot

@echo off
call:RunACmd "..\..\..\fastboot.exe flash ram  ..\..\..\..\..\..\images\light-a-val\light_fastboot_image_single_rank_sec\u-boot-with-spl.bin"
call:RunACmd "..\..\..\fastboot.exe reboot"
ping 127.0.0.1 -n 5 >nul
call:RunACmd "..\..\..\fastboot.exe flash uboot  ..\..\..\..\..\..\images\light-a-val\light_fastboot_image_single_rank_sec\u-boot-with-spl.bin"
call:RunACmd "..\..\..\fastboot.exe flash tf ..\..\..\..\..\..\images\light-a-val\light_fastboot_image_single_rank_sec\tf.ext4"
call:RunACmd "..\..\..\fastboot.exe flash tee ..\..\..\..\..\..\images\light-a-val\light_fastboot_image_single_rank_sec\tee.ext4"
call:RunACmd "..\..\..\fastboot.exe flash boot  ..\..\..\..\..\..\images\light-a-val\boot.ext4"
call:RunACmd "..\..\..\fastboot.exe flash root  ..\..\..\..\..\..\images\light-a-val\rootfs.thead-image-gui.ext4"

pause
exit

:RunACmd
SETLOCAL
set CmdStr=%1
echo IIIIIIIIIIIIIIII Run Cmd:  %CmdStr% 
%CmdStr:~1,-1% || goto RunACmd

GOTO:EOF
