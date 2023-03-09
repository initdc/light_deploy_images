#!/bin/bash

ROOT_PATH=`pwd`
TOOLS_PATH="tools/bin2ext4"

# set default value
MACHINE="light-fm"
IMAGE_PATH=${ROOT_PATH}"/../tmp-glibc/deploy/images/"${MACHINE}
TEE_PATH=${ROOT_PATH}"/../tmp-glibc/work/riscv64-oe-linux/op-tee/0.1-r0/git"
DEB_PATH=${ROOT_PATH}"/../tmp-glibc/deploy/deb"
#echo "ROOT_PATH="${ROOT_PATH}
#echo "IMAGE_PATH="${IMAGE_PATH}

print_help(){
    echo -e "\033[32m ===\t\t This is a script used to generate Linux SDK \t\t\t==\033[0m"
    echo -e "\033[32m ** it will get MACHINE and IMAGE information from file build-id.txt saved in buildhistory** ==\033[0m"
}

# copy boot image
do_copy_boot(){
    echo -e "\033[32m === copy boot image ==\033[0m"
    set -x
    cp ${IMAGE_PATH}/boot.ext4  images/${MACHINE}/
    set +x
}

# copy uboot images
do_copy_uboot(){
    echo -e "\033[32m === copy uboot images ==\033[0m"
    set -x
    mkdir -p images/${MACHINE}/light_fastboot_image_single_rank
    cp ${IMAGE_PATH}/u-boot-with-spl.bin  images/${MACHINE}/light_fastboot_image_single_rank/u-boot-with-spl.bin
    set +x
}

# copy security related images
do_copy_secimages(){
    echo -e "\033[32m === copy security related images ==\033[0m"
    set -x
    if   echo "${MACHINE}" | grep -q "light-a-"; then
        cp -r images/prebuild/light-fm-a/light_fastboot_image_single_rank_sec images/${MACHINE}/
    elif echo "${MACHINE}" | grep -q "light-b-"; then
        cp -r images/prebuild/light-fm-b/light_fastboot_image_single_rank_sec images/${MACHINE}/
    else
        return 0
    fi
    cp ${IMAGE_PATH}/tf.ext4  images/${MACHINE}/light_fastboot_image_single_rank_sec/
    cp ${IMAGE_PATH}/tee.ext4 images/${MACHINE}/light_fastboot_image_single_rank_sec/

    if [ ! -d software/Tsec_dev_kit ]; then
        cp -r ${IMAGE_PATH}/Tsec_dev_kit software/
    fi

    set +x
}

# copy rootfs,if more than one rootfs have been compiled, all of them will be copied
do_copy_rootfs(){
    echo -e "\033[32m === copy rootfs,if more than one rootfs have been compiled, all of them will be copied ==\033[0m"
    set -x
    cp ${IMAGE_PATH}/${IMAGE}-${MACHINE}.ext4 images/${MACHINE}/rootfs.${IMAGE}.ext4
#    if   echo "${IMAGE}" | grep -q "linux-test"; then
#        cp ${IMAGE_PATH}/${IMAGE}-${MACHINE}.ext4 images/${MACHINE}/rootfs.test.ext4
#    else
#        cp ${IMAGE_PATH}/${IMAGE}-${MACHINE}.ext4 images/${MACHINE}/rootfs.ext4
#    fi
    set +x
}

do_copy_vmlinux(){
    echo -e "\033[32m === copy vmlinux to ${MACHINE} ==\033[0m"
    set -x
    MACHINE_UNDERLINE=${MACHINE//"-"/"_"}
    #echo MACHINE_UNDERLINE=${MACHINE_UNDERLINE}
    cp ${ROOT_PATH}/../tmp-glibc/work/${MACHINE_UNDERLINE}-oe-linux/linux-thead/*/linux-${MACHINE_UNDERLINE}-standard-build/vmlinux images/${MACHINE}/
    set +x
}

# copy deb
do_copy_deb(){
    cmd_args=$*
    for item in $cmd_args; do
        if [ "$item" = "no-deb" ]; then
            echo "do_copy_deb() does not executed"
            return 0
        fi
    done

    echo -e "\033[32m === copy deb ==\033[0m"
    set -x
    cp -r ${DEB_PATH} ./
    set +x
}

do_tarball(){
    cmd_args=$*
    for item in $cmd_args; do
        if [ "$item" = "no-tarball" ]; then
            echo "do_tarball() does not executed"
            return 0
        fi
    done

    echo -e "\033[32m === build tarball for ${MACHINE} ==\033[0m"
    set -x
    mkdir -p tarball
    rm -rf /tmp/sdk_tarball/${MACHINE}/images/${MACHINE}
    mkdir -p /tmp/sdk_tarball/${MACHINE}/images/${MACHINE}

    cp -r images/${MACHINE} /tmp/sdk_tarball/${MACHINE}/images/
    cp -r tools /tmp/sdk_tarball/${MACHINE}/

    cd /tmp/sdk_tarball/ && tar -zcvf prebuild_${MACHINE}.tar.gz ${MACHINE} && cd -
    cp /tmp/sdk_tarball/prebuild_${MACHINE}.tar.gz ./tarball/
    set +x
}

do_work(){
    cmd_args=$*

    echo -e "\033[32m === copy images, go through every MACHINE and copy target images ==\033[0m"
    BUILD_INFO_FILE=`find ${ROOT_PATH}/../buildhistory/  -name build-id.txt`
    echo "BUILD_INFO_FILE="${BUILD_INFO_FILE}
    for file in ${BUILD_INFO_FILE}
    do
        info=`cat ${file} |head -n 1`
        echo ${info}
        MACHINE=`echo ${info} |cut -d \: -f 1`
        #echo "MACHINE="${MACHINE}
        IMAGE=`echo ${info} | cut -d \: -f 2 |cut -d ' ' -f 2`
        echo "----------IMAGE="${IMAGE}
        IMAGE_PATH=${ROOT_PATH}"/../tmp-glibc/deploy/images/"${MACHINE}
        #TARGET=`echo ${IMAGE##*-}`
        #echo "TARGET="${TARGET}

        echo "create images/"${MACHINE}
        mkdir -p images/${MACHINE}

        echo -e "\033[36m copy ${MACHINE} images\033[0m"
        do_copy_uboot
        do_copy_secimages
        do_copy_boot
        do_copy_rootfs
        do_copy_vmlinux
        do_tarball $cmd_args
        #break
    done
    do_copy_deb $cmd_args
}

finish(){
    echo -e -e "\033[32m Done \033[0m"
}

# start from here
cmd_args=$*

print_help
do_work $cmd_args
finish

