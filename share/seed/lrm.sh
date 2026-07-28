#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later

debian_release_archived() {
    local release="${1,,}"
    # bullseye remains on regular mirrors (incl. debian-security); only fully
    # retired suites use the debian-archive / debian-elts profiles.
    case "$release" in
    buster|stretch|jessie|wheezy|squeeze|etch|sarge|woody|potato|hamm)
        return 0
        ;;
    esac
    return 1
}

# Suites with Freexian Extended LTS trees on debian-elts mirrors.
debian_release_elts() {
    local release="${1,,}"
    case "$release" in
    buster|stretch|jessie)
        return 0
        ;;
    esac
    return 1
}

# Suites that only exist on old-releases.ubuntu.com (not archive.ubuntu.com
# or China /ubuntu/ mirrors). LTS such as trusty–focal still live under /ubuntu/.
ubuntu_release_archived() {
    local release="${1,,}"
    case "$release" in
    # Interim / very old — present on old-releases, absent from archive.ubuntu.com.
    yakkety|zesty|artful|cosmic|disco|eoan|groovy|hirsute|impish| \
    kinetic|lunar|mantic|oracular| \
    precise|quantal|raring|saucy|utopic|vivid|wily| \
    12.04|12.10|13.04|13.10|15.04|15.10|17.04|17.10|18.10|19.04|19.10| \
    20.10|21.04|21.10|22.10|23.04|23.10|24.10)
        return 0
        ;;
    esac
    return 1
}

centos_release_vault() {
    local release="${1%%.*}"
    [[ "$release" =~ ^[5678]$ ]]
}

# Final vault directory segment for a CentOS major (under centos-vault / vault.centos.org).
centos_vault_release_dir() {
    local releasever="${1%%.*}"
    case "$releasever" in
    5) printf '5.11\n' ;;
    6) printf '6.10\n' ;;
    7) printf '7.9.2009\n' ;;
    8) printf '8.5.2111\n' ;;
    *) printf '%s\n' "$releasever" ;;
    esac
}

release_seed_profile() {
    local profile="$1"
    local release="$2"

    [[ -n "$release" ]] || return 1
    case "$profile" in
    debian)
        # Prefer debian-elts when available (CN tuna + Freexian); else archive.debian.org.
        if debian_release_elts "$release"; then
            printf 'debian-elts\n'
        elif debian_release_archived "$release"; then
            printf 'debian-archive\n'
        fi
        ;;
    ubuntu)
        ubuntu_release_archived "$release" && printf 'ubuntu-old\n'
        ;;
    centos)
        centos_release_vault "$release" && printf 'centos-vault\n'
        ;;
    esac
}

# Map a distro name to a built-in mirror profile (URLs differ per profile).
distro_seed_profile() {
    local distro="${1,,}"
    case "$distro" in
    ubuntu|ubuntukylin|pop|neon|linuxmint|elementary|zorin|peppermint|feren|voyager|bunsenlabs|mx|knoppix|siduction|sparky|gnuinos|avlinux)
        printf 'ubuntu\n' ;;
    kali) printf 'kali\n' ;;
    devuan) printf 'devuan\n' ;;
    deepin|uos) printf 'deepin\n' ;;
    openkylin) printf 'openkylin\n' ;;
    fedora) printf 'fedora\n' ;;
    alma) printf 'alma\n' ;;
    centos|scilinux|sl|springdale|clearos) printf 'centos\n' ;;
    openeuler|euleros|uoseuler|uos-server) printf 'openeuler\n' ;;
    anolis) printf 'anolis\n' ;;
    opencloudos) printf 'opencloudos\n' ;;
    alinux) printf 'alinux\n' ;;
    tencentos) printf 'tencentos\n' ;;
    ctyunos) printf 'ctyunos\n' ;;
    ol) printf 'ol\n' ;;
    amzn) printf 'amzn\n' ;;
    kylin|neokylin|kylinsec|kylinsecos|redflag|isoft|nfslinux|sangfor) printf 'kylin\n' ;;
    arch|manjaro|endeavouros|garuda|cachyos|arcolinux|archcraft|artix|blackarch|hyperbola|parabola|rebornos)
        printf 'arch\n' ;;
    rpm) printf 'rocky\n' ;;
    rhel|eurolinux|cloudlinux|virtuozzo|azurelinux|azl|mariner|cbl-mariner)
        printf 'rocky\n' ;;
    debian|antix|lmde|parrot|pureos|raspbian)
        printf 'debian\n' ;;
    *)
        printf '%s\n' "$(distro_to_family "$distro")"
        ;;
    esac
}

seed_builtin_mirrors() {
    local profile="${1,,}"

    case "$profile" in
    debian)
        mirror_add debian 10 http://deb.debian.org/debian
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/debian
        mirror_add 163 25 https://mirrors.163.com/debian
        mirror_add aliyun 30 https://mirrors.aliyun.com/debian
        mirror_add ustc 35 https://mirrors.ustc.edu.cn/debian
        mirror_add huawei 40 https://mirrors.huaweicloud.com/debian
        mirror_add kernel 50 https://mirrors.kernel.org/debian
        ;;
    debian-archive)
        # China mirrors nest the archive under …/debian-archive/debian (same layout
        # as archive.debian.org/debian). Skip mirrors that do not carry stretch+.
        mirror_add archive 10 http://archive.debian.org/debian
        mirror_add 163 25 https://mirrors.163.com/debian-archive/debian
        mirror_add aliyun 30 https://mirrors.aliyun.com/debian-archive/debian
        mirror_add huawei 40 https://mirrors.huaweicloud.com/debian-archive/debian
        ;;
    debian-elts)
        # Freexian Extended LTS (jessie/stretch/buster). Also seed debian-archive
        # so bwsel can fall back when elts is unreachable.
        mirror_add freexian 10 https://deb.freexian.com/extended-lts
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/debian-elts
        mirror_add archive 40 http://archive.debian.org/debian
        mirror_add 163 45 https://mirrors.163.com/debian-archive/debian
        mirror_add aliyun 50 https://mirrors.aliyun.com/debian-archive/debian
        mirror_add huawei 55 https://mirrors.huaweicloud.com/debian-archive/debian
        ;;
    ubuntu)
        # Includes EOL LTS still hosted on archive.ubuntu.com and China /ubuntu/
        # (trusty, xenial, bionic, focal, …). Do not force ubuntu-old for those.
        mirror_add ubuntu 10 http://archive.ubuntu.com/ubuntu
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/ubuntu
        mirror_add 163 25 https://mirrors.163.com/ubuntu
        mirror_add aliyun 30 https://mirrors.aliyun.com/ubuntu
        mirror_add ustc 35 https://mirrors.ustc.edu.cn/ubuntu
        mirror_add huawei 40 https://mirrors.huaweicloud.com/ubuntu
        mirror_add kernel 50 https://mirrors.kernel.org/ubuntu
        ;;
    ubuntu-old)
        # Nest …/ubuntu-old-releases/ubuntu like upstream old-releases.ubuntu.com/ubuntu.
        # Many CN hosts lack this tree; keep ustc + upstream.
        mirror_add ubuntu 10 http://old-releases.ubuntu.com/ubuntu
        mirror_add ustc 20 https://mirrors.ustc.edu.cn/ubuntu-old-releases/ubuntu
        ;;
    kali)
        mirror_add kali 10 http://http.kali.org/kali
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/kali
        mirror_add aliyun 30 https://mirrors.aliyun.com/kali
        mirror_add ustc 40 https://mirrors.ustc.edu.cn/kali
        ;;
    devuan)
        mirror_add devuan 10 http://deb.devuan.org/merged
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/devuan
        mirror_add aliyun 30 https://mirrors.aliyun.com/devuan
        ;;
    deepin)
        mirror_add deepin 10 https://community.deepin.com/deepin
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/deepin
        mirror_add aliyun 30 https://mirrors.aliyun.com/deepin
        mirror_add ustc 40 https://mirrors.ustc.edu.cn/deepin
        mirror_add huawei 50 https://mirrors.huaweicloud.com/deepin
        ;;
    openkylin)
        mirror_add openkylin 10 https://mirror.cyberkylin.org/openkylin
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/openkylin
        mirror_add aliyun 30 https://mirrors.aliyun.com/openkylin
        ;;
    fedora)
        mirror_add fedora 10 https://download.fedoraproject.org/pub/fedora/linux
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/fedora
        mirror_add 163 25 https://mirrors.163.com/fedora
        mirror_add aliyun 30 https://mirrors.aliyun.com/fedora
        mirror_add ustc 40 https://mirrors.ustc.edu.cn/fedora
        mirror_add huawei 50 https://mirrors.huaweicloud.com/fedora
        ;;
    rocky)
        mirror_add rocky 10 https://dl.rockylinux.org/pub/rocky
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/rocky
        mirror_add 163 25 https://mirrors.163.com/rockylinux
        mirror_add aliyun 30 https://mirrors.aliyun.com/rockylinux
        mirror_add ustc 40 https://mirrors.ustc.edu.cn/rockylinux
        mirror_add huawei 50 https://mirrors.huaweicloud.com/rockylinux
        ;;
    alma)
        mirror_add alma 10 https://repo.almalinux.org/almalinux
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/almalinux
        mirror_add 163 25 https://mirrors.163.com/almalinux
        mirror_add aliyun 30 https://mirrors.aliyun.com/almalinux
        mirror_add ustc 40 https://mirrors.ustc.edu.cn/almalinux
        mirror_add huawei 50 https://mirrors.huaweicloud.com/almalinux
        ;;
    centos)
        # CentOS Stream 9+. Prefer centos-stream trees; bare /centos/ is legacy.
        mirror_add centos 10 https://mirrors.centos.org/centos-stream
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/centos-stream
        mirror_add aliyun 30 https://mirrors.aliyun.com/centos-stream
        mirror_add ustc 40 https://mirrors.ustc.edu.cn/centos-stream
        mirror_add huawei 50 https://mirrors.huaweicloud.com/centos-stream
        ;;
    centos-vault)
        # EOL CentOS 5–8 live under centos-vault (not bare /centos/ on CN mirrors).
        mirror_add centos 10 https://vault.centos.org
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/centos-vault
        mirror_add 163 25 https://mirrors.163.com/centos-vault
        mirror_add aliyun 30 https://mirrors.aliyun.com/centos-vault
        mirror_add ustc 40 https://mirrors.ustc.edu.cn/centos-vault
        mirror_add huawei 50 https://mirrors.huaweicloud.com/centos-vault
        ;;
    openeuler)
        mirror_add openeuler 10 https://repo.openeuler.org
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/openeuler
        mirror_add aliyun 30 https://mirrors.aliyun.com/openeuler
        mirror_add ustc 40 https://mirrors.ustc.edu.cn/openeuler
        mirror_add huawei 50 https://mirrors.huaweicloud.com/openeuler
        ;;
    anolis)
        mirror_add anolis 10 https://mirrors.openanolis.cn/anolis
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/anolis
        mirror_add aliyun 30 https://mirrors.aliyun.com/anolis
        mirror_add huawei 40 https://mirrors.huaweicloud.com/anolis
        ;;
    opencloudos)
        mirror_add opencloudos 10 https://mirrors.opencloudos.org/opencloudos
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/opencloudos
        mirror_add aliyun 30 https://mirrors.aliyun.com/opencloudos
        mirror_add huawei 40 https://mirrors.huaweicloud.com/opencloudos
        ;;
    alinux)
        mirror_add alinux 10 https://mirrors.aliyun.com/alinux
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/alinux
        mirror_add huawei 30 https://mirrors.huaweicloud.com/alinux
        ;;
    tencentos)
        mirror_add tencentos 10 https://mirrors.tencent.com/tlinux
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/tencentos
        mirror_add aliyun 30 https://mirrors.aliyun.com/tencentos
        ;;
    ctyunos)
        mirror_add ctyunos 10 https://mirrors.ctyun.cn/ctyunos
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/ctyunos
        mirror_add aliyun 30 https://mirrors.aliyun.com/ctyunos
        ;;
    ol)
        mirror_add oracle 10 https://yum.oracle.com/repo/OracleLinux
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/oraclelinux
        mirror_add aliyun 30 https://mirrors.aliyun.com/oraclelinux
        mirror_add huawei 40 https://mirrors.huaweicloud.com/oraclelinux
        ;;
    amzn)
        mirror_add amazon 10 https://cdn.amazonlinux.com
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/amazonlinux
        mirror_add aliyun 30 https://mirrors.aliyun.com/amazonlinux
        ;;
    kylin)
        mirror_add kylin 10 https://archive.kylinos.cn/kylin/KYLIN-ALL
        mirror_add huawei 20 https://mirrors.huaweicloud.com/kylin
        mirror_add tuna 30 https://mirrors.tuna.tsinghua.edu.cn/kylin
        ;;
    arch)
        mirror_add geo 10 https://geo.mirror.pkgbuild.com
        mirror_add tuna 20 https://mirrors.tuna.tsinghua.edu.cn/archlinux
        mirror_add 163 25 https://mirrors.163.com/archlinux
        mirror_add aliyun 30 https://mirrors.aliyun.com/archlinux
        mirror_add ustc 35 https://mirrors.ustc.edu.cn/archlinux
        mirror_add kernel 50 https://mirrors.kernel.org/archlinux
        ;;
    rpm)
        seed_builtin_mirrors rocky
        ;;
    *)
        die "$(printf "$(_ 'no built-in default mirrors for distribution: %s')" "${profile:-unknown}")"
        ;;
    esac
}

seed_default_mirrors_for() {
    local distro="$1"
    local profile archive_profile release="${LRM_RELEASE:-}"

    profile="$(distro_seed_profile "$distro")"
    archive_profile="$(release_seed_profile "$profile" "$release" || true)"
    [[ -n "$archive_profile" ]] && profile="$archive_profile"
    seed_builtin_mirrors "$profile"
}

ensure_mirrors() {
    if [[ -f "$MIRROR_FILE" ]]; then
        load_mirrors
        return 0
    fi

    local distro="${LRM_DISTRO_ID:-${LRM_DISTRO:-$(get_effective_distro)}}"
    if [[ "$distro" == *:* ]]; then
        parse_distro_spec "$distro"
        distro="$LRM_DISTRO_ID"
    fi
    seed_default_mirrors_for "$distro"
    save_mirrors
    MIRRORS_LOADED=1
    vlog "$(printf "$(_ 'installed default mirrors for %s')" "$(distro_spec_display 2>/dev/null || printf '%s' "$distro")")"
}
