# 目录说明

```
.
├── readme.md
├── sdk.sh   // 镜像打包脚本
├── software // 存放 TA SDK 以及其他软件
├── tarball  // 镜像目录，存放编译好的镜像文件
└── tools    // 工具目录，存放 fastboot 烧录工具和其他工具
```

# 镜像打包脚本

“sdk.sh” 脚本可以用来将编译好的镜像打包。使用说明：

1. 将该目录拷贝到编译完成的 light-fm 文件夹下
2. 运行脚本：./sdk.sh

# tarball 镜像目录

存放打包好的镜像文件，将 tar 包解压后，配合 tools 目录下的 fastboot 工具，可以将镜像烧录到开发板。

解压后镜像说明：

* u-boot-with-spl.bin：u-boot镜像
* boot.ext4：启动镜像，包括 kernel image、kernel dtb、opensbi 等内容
* rootfs.xxx.ext4：Yocto 文件系统镜像
* tee.ext4/tf.ext4：安全镜像

# fastboot 烧录

在 tools/fastboot 文件夹下，存放了用来烧录的 fastboot 工具，支持 Linux/mac/windows 平台使用。

以 Linux 平台为例，进入目录：tools/fastboot/linux/scripts/light-a/normal，可以看到多个烧录脚本，分别对应不同的镜像烧录。打开 light_fm_single_rank_full_image.sh，内容如下：

```
#! /bin/sh                                                                                                                                                                          
# Script to flash imagess via fastboot
#


sudo ../../../fastboot flash ram ../../../../../../images/light-a-val/light_fastboot_image_single_rank/u-boot-with-spl.bin
sudo ../../../fastboot reboot
sleep 10
sudo ../../../fastboot flash uboot ../../../../../../images/light-a-val/light_fastboot_image_single_rank/u-boot-with-spl.bin
sudo ../../../fastboot flash boot ../../../../../../images/light-a-val/boot.ext4
sudo ../../../fastboot flash root ../../../../../../images/light-a-val/rootfs.light-fm-image-linux.ext4
```

运行该脚本，fastboot 会自动按照内容烧录 images 镜像目录里面的镜像

> 注意：不同的平台在 images 目录下的名字可能不一样，请根据实际情况修改脚本。

更多烧录说明，请参考：《[T-Head曳影1520验证板镜像烧写用户指南.pdf](https://gitee.com/thead-yocto/documents/blob/master/zh/user_guide/T-Head%E6%9B%B3%E5%BD%B11520%E9%AA%8C%E8%AF%81%E6%9D%BF%E9%95%9C%E5%83%8F%E7%83%A7%E5%86%99%E7%94%A8%E6%88%B7%E6%8C%87%E5%8D%97.pdf)》
