#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later

# Debian-family distros (apt). Includes Deepin/UOS desktop, openKylin, etc.
readonly -a _LRM_DEBIAN_DISTROS=(
    antix avlinux bunsenlabs debian deepin devuan elementary feren gnuinos
    kali knoppix lmde linuxmint mx neon parrot peppermint pop pureos raspbian
    siduction sparky ubuntu ubuntukylin uos voyager zorin openkylin
)

# RPM-family distros (dnf/yum). Includes Kylin, openEuler, UOS Server, etc.
readonly -a _LRM_RPM_DISTROS=(
    alinux alma amzn anolis azurelinux azl cbl-mariner centos clearos cloudlinux
    ctyunos eurolinux euleros fedora isoft kylin kylinsec kylinsecos mariner
    neokylin nfslinux ol opencloudos openeuler redflag rhel rocky rpm sangfor
    scilinux sl springdale tencentos uos-server uoseuler virtuozzo
)

# SUSE-family distros (zypper).
readonly -a _LRM_SUSE_DISTROS=(
    opensuse opensuse-leap opensuse-tumbleweed sled sles suse
)

# Arch-family distros (pacman).
readonly -a _LRM_ARCH_DISTROS=(
    arch arcolinux archcraft artix blackarch cachyos endeavouros garuda hyperbola
    manjaro parabola rebornos
)

# All names accepted by -o/--distro (includes family alias rpm).
LRM_SUPPORTED_DISTROS=(
    "${_LRM_DEBIAN_DISTROS[@]}"
    "${_LRM_RPM_DISTROS[@]}"
    "${_LRM_SUSE_DISTROS[@]}"
    "${_LRM_ARCH_DISTROS[@]}"
    rpm
)

_distro_in_list() {
    local name="$1"
    shift
    local d
    for d in "$@"; do
        [[ "$d" == "$name" ]] && return 0
    done
    return 1
}

_family_for_distro_id() {
    local id="${1,,}"
    if _distro_in_list "$id" "${_LRM_DEBIAN_DISTROS[@]}"; then
        printf 'debian\n'
        return 0
    fi
    if _distro_in_list "$id" "${_LRM_RPM_DISTROS[@]}"; then
        printf 'rpm\n'
        return 0
    fi
    if _distro_in_list "$id" "${_LRM_SUSE_DISTROS[@]}"; then
        printf 'suse\n'
        return 0
    fi
    if _distro_in_list "$id" "${_LRM_ARCH_DISTROS[@]}"; then
        printf 'arch\n'
        return 0
    fi
    return 1
}

normalize_distro_name() {
    local name="${1,,}"
    case "$name" in
    redhat) printf 'rhel\n' ;;
    oracle|oraclelinux) printf 'ol\n' ;;
    amazon|amazonlinux) printf 'amzn\n' ;;
    mint) printf 'linuxmint\n' ;;
    uniontech|chinauos) printf 'uos\n' ;;
    uos-server|uosserver|uniontech-server|uniontechos-server) printf 'uos-server\n' ;;
    rockylinux) printf 'rocky\n' ;;
    almalinux) printf 'alma\n' ;;
    opensuse-leap|leap) printf 'opensuse\n' ;;
    opensuse-tumbleweed|tumbleweed) printf 'opensuse-tumbleweed\n' ;;
    suse-sle|sle) printf 'sles\n' ;;
    openeuler-os|open-euler) printf 'openeuler\n' ;;
    euler) printf 'euleros\n' ;;
    neokylin-linux|neokylinos) printf 'neokylin\n' ;;
    openkylinos) printf 'openkylin\n' ;;
    tencent|tlinux) printf 'tencentos\n' ;;
    ctyun|ctyun-os) printf 'ctyunos\n' ;;
    alios|alibabacloud) printf 'alinux\n' ;;
    kylinos|kylin-linux|kylinserver) printf 'kylin\n' ;;
    scientific|scientificlinux) printf 'scilinux\n' ;;
    centos-stream|centosstream) printf 'centos\n' ;;
    azure-linux|azure) printf 'azurelinux\n' ;;
    *) printf '%s\n' "$name" ;;
    esac
}

distro_is_supported() {
    local distro="$1"
    _distro_in_list "$distro" "${LRM_SUPPORTED_DISTROS[@]}"
}

validate_distro() {
    local distro="$1"
    distro_is_supported "$distro" || \
        die "$(printf "$(_ 'unsupported distro: %s (see: lrm --list-distros)')" "$distro")"
}

distro_to_family() {
    local distro="${1,,}"
    if _family_for_distro_id "$distro"; then
        return 0
    fi
    die "$(printf "$(_ 'unsupported distro: %s (see: lrm --list-distros)')" "$distro")"
}

# UnionTech OS Server (openEuler/openAnolis) sets PLATFORM_ID=platform:uel*.
_uos_is_server() {
    [[ "${PLATFORM_ID:-}" == platform:uel* ]]
}

detect_host_release() {
    local family="$1"

    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        case "$family" in
        debian)
            if [[ -n "${VERSION_CODENAME:-}" ]]; then
                printf '%s\n' "$VERSION_CODENAME"
                return 0
            fi
            if [[ -n "${UBUNTU_CODENAME:-}" ]]; then
                printf '%s\n' "$UBUNTU_CODENAME"
                return 0
            fi
            ;;
        rpm)
            if [[ -n "${VERSION_ID:-}" ]]; then
                printf '%s\n' "${VERSION_ID%%.*}"
                return 0
            fi
            ;;
        esac
    fi
    printf '\n'
}

distro_spec_to_state_key() {
    local id="$1"
    local release="${2:-}"

    if [[ -n "$release" ]]; then
        printf '%s/%s\n' "$id" "$release"
    else
        printf '%s\n' "$id"
    fi
}

parse_distro_spec() {
    local spec="$1"
    local id release

    if [[ "$spec" == *:* ]]; then
        id="${spec%%:*}"
        release="${spec#*:}"
        if [[ "$release" == *:* ]]; then
            die "$(printf "$(_ 'invalid distro spec (too many colons): %s')" "$spec")"
        fi
        [[ -n "$id" && -n "$release" ]] || \
            die "$(printf "$(_ 'invalid distro spec: %s')" "$spec")"
    else
        id="$spec"
        release=""
    fi

    id="$(normalize_distro_name "$id")"
    validate_distro "$id"
    LRM_DISTRO_ID="$id"
    LRM_RELEASE="$release"
}

distro_spec_display() {
    if [[ -n "${LRM_RELEASE:-}" ]]; then
        printf '%s:%s\n' "$LRM_DISTRO_ID" "$LRM_RELEASE"
    else
        printf '%s\n' "$LRM_DISTRO_ID"
    fi
}

apply_distro_release_vars() {
    case "$(distro_to_family "$LRM_DISTRO_ID")" in
    debian)
        if [[ -n "${LRM_RELEASE:-}" ]]; then
            LRM_SUITE="$LRM_RELEASE"
        fi
        ;;
    rpm)
        if [[ -n "${LRM_RELEASE:-}" ]]; then
            LRM_RELEASEVER="${LRM_RELEASE%%.*}"
        fi
        ;;
    suse)
        if [[ -n "${LRM_RELEASE:-}" ]]; then
            LRM_ZYPPER_RELEASE="$LRM_RELEASE"
        fi
        ;;
    esac
}

detect_host_distro_spec() {
    local id release family spec

    id="$(detect_host_distro)"
    if [[ "$id" == unknown ]]; then
        printf 'unknown\n'
        return 0
    fi
    family="$(distro_to_family "$id")"
    release="$(detect_host_release "$family")"
    if [[ -n "$release" ]]; then
        spec="$id:$release"
    else
        spec="$id"
    fi
    printf '%s\n' "$spec"
}

resolve_distro_spec() {
    local spec id release family

    if [[ -n "${LRM_DISTRO:-}" ]]; then
        spec="$LRM_DISTRO"
    else
        id="$(detect_host_distro)"
        if [[ "$id" == unknown ]]; then
            die "$(_ 'could not detect host distribution; use -o/--distro NAME[:RELEASE]')"
        fi
        family="$(distro_to_family "$id")"
        release="$(detect_host_release "$family")"
        if [[ -n "$release" ]]; then
            spec="$id:$release"
        else
            spec="$id"
        fi
    fi

    parse_distro_spec "$spec"
    LRM_DISTRO="$LRM_DISTRO_ID"
    LRM_DISTRO_KEY="$(distro_spec_to_state_key "$LRM_DISTRO_ID" "$LRM_RELEASE")"
    apply_distro_release_vars
}

detect_host_distro() {
    local id family

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
    id="$(normalize_distro_name "${ID:-}")"
    if [[ "$id" == uos ]] && _uos_is_server; then
        id=uos-server
    fi
    if distro_is_supported "$id"; then
        printf '%s\n' "$id"
        return 0
    fi

    family="$(detect_distro_family)"
    case "$family" in
    debian) printf 'debian\n' ;;
    rpm) printf 'rocky\n' ;;
    arch) printf 'arch\n' ;;
    *) printf 'unknown\n' ;;
    esac
}

get_effective_distro() {
    if [[ -n "${LRM_DISTRO_ID:-}" ]]; then
        distro_spec_display
        return 0
    fi

    local spec
    spec="$(detect_host_distro_spec)"
    if [[ "$spec" == unknown ]]; then
        die "$(_ 'could not detect host distribution; use -o/--distro NAME[:RELEASE]')"
    fi
    printf '%s\n' "$spec"
}

list_supported_distros() {
    printf '%s\n' "${LRM_SUPPORTED_DISTROS[@]}" | LC_ALL=C sort -u
}

load_distro_backend() {
    resolve_distro_spec
    load_distro_backend_for "$(distro_to_family "$LRM_DISTRO_ID")"
    lrm_set_distro_state
    vlog2 "distribution: $(distro_spec_display) (family: $DISTRO_FAMILY, state: $LRM_DISTRO_KEY)"
}

load_distro_backend_for() {
    local family="$1"
    DISTRO_FAMILY="$family"
    vlog2 "distribution family: $family"
    case "$family" in
        debian)
            # shellcheck source=share/var/debian.sh
            source "$SHARE_DIR/var/debian.sh"
            ;;
        rpm|centos)
            DISTRO_FAMILY=rpm
            # shellcheck source=share/var/rpm.sh
            source "$SHARE_DIR/var/rpm.sh"
            ;;
        suse|sles|opensuse)
            DISTRO_FAMILY=suse
            # shellcheck source=share/var/zypper.sh
            source "$SHARE_DIR/var/zypper.sh"
            ;;
        arch)
            # shellcheck source=share/arch.sh
            source "$SHARE_DIR/arch.sh"
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
    if [[ "$id" == uos ]] && _uos_is_server; then
        id=uos-server
    fi
    if _family_for_distro_id "$id"; then
        return 0
    fi

    like="${ID_LIKE:-}"
    case "$like" in
        *debian*) printf 'debian\n' ; return 0 ;;
        *rhel*|*fedora*|*centos*) printf 'rpm\n' ; return 0 ;;
        *suse*|*opensuse*) printf 'suse\n' ; return 0 ;;
        *arch*) printf 'arch\n' ; return 0 ;;
    esac

    printf 'unknown\n'
}
