#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later

load_distro_backend() {
    load_distro_backend_for "$(detect_distro_family)"
}

load_distro_backend_for() {
    local family="$1"
    DISTRO_FAMILY="$family"
    vlog2 "distribution family: $family"
    case "$family" in
        debian)
            # shellcheck source=debian.sh
            source "$LIB_DIR/debian.sh"
            ;;
        rpm|centos)
            DISTRO_FAMILY=rpm
            # shellcheck source=rpm.sh
            source "$LIB_DIR/rpm.sh"
            ;;
        arch)
            # shellcheck source=arch.sh
            source "$LIB_DIR/arch.sh"
            ;;
        *)
            die "$(printf "$(_ 'unsupported distribution family: %s')" "${family:-unknown}")"
            ;;
    esac
}

detect_distro_family() {
    local id like
    if [[ ! -f /etc/os-release ]]; then
        if [[ -f /etc/debian_version ]]; then
            printf 'debian\n'
            return 0
        fi
        if [[ -f /etc/redhat-release ]]; then
            printf 'rpm\n'
            return 0
        fi
        printf 'unknown\n'
        return 0
    fi

    # shellcheck disable=SC1091
    source /etc/os-release
    id="${ID,,}"
    like="${ID_LIKE:-}"

    case "$id" in
        debian|ubuntu|linuxmint|pop|elementary|zorin|kali|raspbian)
            printf 'debian\n'
            return 0
            ;;
        centos|rhel|rocky|alma|fedora|ol|amzn|virtuozzo|opencloudos|anolis)
            printf 'rpm\n'
            return 0
            ;;
        arch|manjaro|endeavouros|garuda)
            printf 'arch\n'
            return 0
            ;;
    esac

    case "$like" in
        *debian*) printf 'debian\n' ; return 0 ;;
        *rhel*|*fedora*) printf 'rpm\n' ; return 0 ;;
        *arch*) printf 'arch\n' ; return 0 ;;
    esac

    printf 'unknown\n'
}
