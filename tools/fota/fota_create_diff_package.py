#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright (C) 2018-2021 Alibaba Group Holding Limited
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import sys
import hashlib
import base64
import tarfile


def get_file_sha1(path):
    sha1 = hashlib.sha1()
    with open(path, "rb") as f:
        while True:
            data = f.read(2048)
            if not data:
                break
            sha1.update(data)
    return base64.b64encode(sha1.digest()).decode('utf-8 ')


def list_files(file_list, path, base):
    lsdir = os.listdir(path)
    dirs = [i for i in lsdir if os.path.isdir(os.path.join(path, i)) and os.path.islink(os.path.join(path, i)) == False]
    if dirs:
        for i in dirs:
            list_files(file_list, os.path.join(path, i), base)
            file_list.append(os.path.relpath(os.path.abspath(os.path.join(path,i)), os.path.abspath(base)))
    files = [i for i in lsdir]
    for f in files:
        file_list.append(os.path.relpath(os.path.abspath(os.path.join(path,f)), os.path.abspath(base)))


def create_package(old_dir, new_dir, output_dir, part_name):
    old_dir = os.path.abspath(old_dir)
    new_dir = os.path.abspath(new_dir)
    output_dir = os.path.abspath(output_dir)
    dir_old = []
    dir_new = []
    list_files(dir_old, old_dir, old_dir)
    list_files(dir_new, new_dir, new_dir)
    file_matched = list(set(dir_old).intersection(set(dir_new)))
    file_deleted = list(set(dir_old) - set(dir_new))
    file_added = list(set(dir_new) - set(dir_old))

    file_chmod = []
    for f in file_matched:
        file_name_old = old_dir + "/" + f
        file_name_new = new_dir + "/" + f
        # folder
        if os.path.isdir(file_name_new) or os.path.isdir(file_name_old) :
            if os.path.isdir(file_name_new) != os.path.isdir(file_name_old) :
                file_deleted.append(f)
                file_added.append(f)
            # both are folders
            elif (os.lstat(file_name_old).st_mode & 0x1ff) != (os.lstat(file_name_new).st_mode & 0x1ff) \
                or os.lstat(file_name_old).st_uid != os.lstat(file_name_new).st_uid \
                or os.lstat(file_name_old).st_gid != os.lstat(file_name_new).st_gid :
                file_chmod.append(f)
        # link file
        elif os.path.islink(file_name_new) or os.path.islink(file_name_old) :
            if os.path.islink(file_name_new) != os.path.islink(file_name_old) :
                file_deleted.append(f)
                file_added.append(f)
            elif (os.lstat(file_name_old).st_mode & 0x1ff) != (os.lstat(file_name_new).st_mode & 0x1ff) \
                or os.lstat(file_name_old).st_uid != os.lstat(file_name_new).st_uid \
                or os.lstat(file_name_old).st_gid != os.lstat(file_name_new).st_gid \
                or str(os.readlink(file_name_old)) != str(os.readlink(file_name_new)):
                file_deleted.append(f)
                file_added.append(f)
        # file
        else :
            n = get_file_sha1(file_name_new)
            o = get_file_sha1(file_name_old)
            if n != o :
                file_deleted.append(f)
                file_added.append(f)
            elif (os.lstat(file_name_old).st_mode & 0x1ff) != (os.lstat(file_name_new).st_mode & 0x1ff) \
                or os.lstat(file_name_old).st_uid != os.lstat(file_name_new).st_uid \
                or os.lstat(file_name_old).st_gid != os.lstat(file_name_new).st_gid :
                file_chmod.append(f)

    # if no need update return 0
    if len(file_deleted) == 0 and len(file_added) == 0 and len(file_chmod) == 0 :
        return 0

    # make update data
    file_mkdir = []
    cwd_bak = os.getcwd()
    os.chdir(new_dir)
    tar = tarfile.open(("%s/%s.tar.gz" % (output_dir, part_name)), "w:gz")
    file_added = sorted(file_added, key=len, reverse=True)
    for f in file_added:
        if os.path.isdir(new_dir + "/" + f) :
            file_mkdir.append(f)
            file_chmod.append(f)
        else :
            tar.add(f)
    tar.close()
    os.chdir(cwd_bak)

    # make update script
    shell_str = ("#!/bin/sh\n\nset -e\nif [ $# != 2 ];" \
        "then exit 1; fi\ntar_dir=`realpath $1`\ncd $2/%s\n") % part_name
    file_deleted = sorted(file_deleted, key=len, reverse=True)
    for f in file_deleted:
        shell_str += ("rm -rf %s\n" %f)
    file_mkdir = sorted(file_mkdir, key=len)
    for f in file_mkdir :
        shell_str += "mkdir -p " + f + "\n"
    shell_str += ("cd $2\ntar -zxf $tar_dir %s\ncd $2/%s\n") % (part_name, part_name)
    file_chmod = sorted(file_chmod, key=len)
    for f in file_chmod:
        file_name_new = new_dir + "/" + f
        shell_str += ("chmod %o %s\n" %(os.lstat(file_name_new).st_mode & 0x1ff, f))
        shell_str += ("chown %d:%d %s\n" %(os.lstat(file_name_new).st_uid, os.lstat(file_name_new).st_gid, f))
    fp = open(("%s/update_%s.sh" % (output_dir, part_name)), "wb+")
    fp.write(shell_str)
    fp.flush()
    fp.close()
    os.system(("chmod +x %s/update_%s.sh" % (output_dir, part_name)))

    return 1


def mount_img(old_img, new_img, old_dir, new_dir):
    if os.system(("mount %s %s" % (old_img, old_dir))) :
        print("mount old img error")
        os.system("ls fota__out_")
        return -1
    if os.system(("mount %s %s" % (new_img, new_dir))) :
        os.system(("umount %s" % (old_img, old_dir)))
        print("mount new img error")
        return -1
    return 0


def main():
    if (len(sys.argv) - 1) / 3 < 1:
        print('Usage: sudo %s part_name1 old_img1 new_img1 ...' % sys.argv[0])
        return 1
    if (len(sys.argv) - 1) % 3 :
        print('Usage: sudo %s part_name1 old_img1 new_img1 ...' % sys.argv[0])
        return 1

    output_dir = "fota__out_"
    old_dir = ("%s/old" % output_dir)
    new_dir = ("%s/new" % output_dir)
    out_dir = ("%s/out" % output_dir)
    if os.system(("mkdir -p %s %s %s" % (old_dir, new_dir, out_dir))) :
        os.system(("rm -rf %s") % output_dir)
        print("mkdir error")
        return -1
    need_update = 0
    for i in range(0, (len(sys.argv) - 1) / 3):
        index = i * 3
        part_name = sys.argv[1 + index]
        if mount_img(sys.argv[2 + index], sys.argv[3 + index], old_dir, new_dir) :
            os.system(("rm -rf %s") % output_dir)
            return -1
        if create_package(old_dir, new_dir, out_dir, part_name) == 0 :
            os.system(("umount %s %s") % (old_dir, new_dir))
            print("%s: no need update" % part_name)
            continue
        need_update = 1
        ret = os.system((("set -e\n"
                "umount %s %s\n"
                "cd %s\n"
                "mkdir -p %s\n"
                "rm -rf %s/*\n"
                "tar -zxf %s.tar.gz -C %s\n"
                "rm %s.tar.gz\n") % (old_dir, new_dir, out_dir,
                part_name, part_name, part_name, part_name, part_name)))
        if ret :
            os.system(("rm -rf %s") % output_dir)
            print("error")
            return -1

    if need_update == 0 :
        os.system(("rm -rf %s") % output_dir)
        print("all: no need update")
        return 0
    ret = os.system((("set -e\n"
            "cd %s && tar cfz ../../diff.bin *\n"
            "cd ../../ && rm -rf %s\n") % (out_dir, output_dir)))
    if ret :
        os.system(("rm -rf %s") % output_dir)
        print("error")
        return -1
    print("ok")
    return 0


if __name__ == '__main__':
    sys.exit(main())
