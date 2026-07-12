#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later

seed_default_mirrors_for() {
    local family="$1"

    case "$family" in
    debian)
        mirror_add debian 10 http://deb.debian.org/debian
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/debian
        mirror_add 163 25 https://mirrors.163.com/debian
        mirror_add aliyun 30 https://mirrors.aliyun.com/debian
        mirror_add ustc 35 https://mirrors.ustc.edu.cn/debian
        mirror_add huawei 40 https://mirrors.huaweicloud.com/debian
        mirror_add kernel 50 https://mirrors.kernel.org/debian
        ;;
    rpm|centos)
        mirror_add rocky 10 https://dl.rockylinux.org/pub/rocky
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/rocky
        mirror_add 163 25 https://mirrors.163.com/rockylinux
        mirror_add aliyun 30 https://mirrors.aliyun.com/rockylinux
        mirror_add ustc 40 https://mirrors.ustc.edu.cn/rockylinux
        mirror_add huawei 50 https://mirrors.huaweicloud.com/rockylinux
        ;;
    arch)
        mirror_add geo 10 https://geo.mirror.pkgbuild.com
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/archlinux
        mirror_add 163 25 https://mirrors.163.com/archlinux
        mirror_add aliyun 30 https://mirrors.aliyun.com/archlinux
        mirror_add ustc 35 https://mirrors.ustc.edu.cn/archlinux
        mirror_add kernel 50 https://mirrors.kernel.org/archlinux
        ;;
    *)
        die "$(printf "$(_ 'no built-in default mirrors for distribution family: %s')" "${family:-unknown}")"
        ;;
    esac
}

ensure_mirrors() {
    if [[ -f "$LRM_MIRROR_FILE" ]]; then
        load_mirrors
        return 0
    fi

    local family="${LRM_FAMILY:-${DISTRO_FAMILY:-}}"
    if [[ -z "$family" || "$family" == unknown ]]; then
        family="$(detect_distro_family)"
    fi
    case "$family" in
    centos) family=rpm ;;
    esac

    seed_default_mirrors_for "$family"
    save_mirrors
    LRM_MIRRORS_LOADED=1
    vlog "installed default mirrors for $family"
}
