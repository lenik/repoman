#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later

detect_debian_suite() {
    if [[ -n "${LRM_RELEASE:-}" ]]; then
        printf '%s\n' "$LRM_RELEASE"
        return 0
    fi
    if [[ -n "${LRM_SUITE:-}" ]]; then
        printf '%s\n' "$LRM_SUITE"
        return 0
    fi
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        if [[ -n "${VERSION_CODENAME:-}" ]]; then
            printf '%s\n' "$VERSION_CODENAME"
            return 0
        fi
    fi
    printf '%s\n' "bookworm"
}

debian_security_mirror_url() {
    local url="${1%/}"
    if [[ "$url" == *archive.debian.org* ]]; then
        if [[ "$url" == */debian ]]; then
            printf '%s-security\n' "$url"
        else
            printf '%s/debian-security\n' "$url"
        fi
        return 0
    fi
    if [[ "$url" == *debian-archive* ]]; then
        printf '%s/debian-security\n' "$url"
        return 0
    fi
    if [[ "$url" == */debian ]]; then
        printf '%s-security\n' "$url"
        return 0
    fi
    printf '%s/debian-security\n' "$url"
}

mirror_probe_url() {
    local base="${1%/}"
    local suite="${LRM_SUITE:-$(detect_debian_suite)}"
    printf '%s/dists/%s/Release\n' "$base" "$suite"
}

lrm_debian_apply_defaults() {
    LRM_DEB_SRC=1
    LRM_DEB_UPDATES=1
    LRM_DEB_BACKPORTS=1
    LRM_DEB_SECURITY=1
    LRM_DEB_COMPONENTS="main contrib non-free non-free-firmware"
}

lrm_debian_apply_minimal() {
    LRM_DEB_SRC=0
    LRM_DEB_UPDATES=0
    LRM_DEB_BACKPORTS=0
    LRM_DEB_SECURITY=0
    LRM_DEB_COMPONENTS="main"
}

# Parse options for use / pingsel / bwsel. Leaves mirror target in $1 on return.
parse_apply_opts() {
    local suite="${LRM_SUITE:-$(detect_debian_suite)}"

    lrm_debian_apply_defaults
    LRM_CONFIG_ONLY=0
    LRM_SUITE="$suite"
    PARSE_APPLY_TARGET=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -c|--config-only) LRM_CONFIG_ONLY=1; shift ;;
        -a|--all) lrm_debian_apply_defaults; shift ;;
        --minimal) lrm_debian_apply_minimal; shift ;;
        -s|--src) LRM_DEB_SRC=1; shift ;;
        --no-src) LRM_DEB_SRC=0; shift ;;
        -u|--updates) LRM_DEB_UPDATES=1; shift ;;
        --no-updates) LRM_DEB_UPDATES=0; shift ;;
        -b|--backports) LRM_DEB_BACKPORTS=1; shift ;;
        --no-backports) LRM_DEB_BACKPORTS=0; shift ;;
        --security) LRM_DEB_SECURITY=1; shift ;;
        --no-security) LRM_DEB_SECURITY=0; shift ;;
        --contrib)
            LRM_DEB_COMPONENTS+=" contrib"
            LRM_DEB_COMPONENTS="$(printf '%s\n' "$LRM_DEB_COMPONENTS" | tr ' ' '\n' | awk '!seen[$0]++' | tr '\n' ' ')"
            LRM_DEB_COMPONENTS="${LRM_DEB_COMPONENTS% }"
            shift
            ;;
        --non-free)
            LRM_DEB_COMPONENTS+=" non-free"
            LRM_DEB_COMPONENTS="$(printf '%s\n' "$LRM_DEB_COMPONENTS" | tr ' ' '\n' | awk '!seen[$0]++' | tr '\n' ' ')"
            LRM_DEB_COMPONENTS="${LRM_DEB_COMPONENTS% }"
            shift
            ;;
        --firmware)
            LRM_DEB_COMPONENTS+=" non-free-firmware"
            LRM_DEB_COMPONENTS="$(printf '%s\n' "$LRM_DEB_COMPONENTS" | tr ' ' '\n' | awk '!seen[$0]++' | tr '\n' ' ')"
            LRM_DEB_COMPONENTS="${LRM_DEB_COMPONENTS% }"
            shift
            ;;
        --suite)
            [[ $# -ge 2 ]] || die "$(_ 'usage: --suite SUITE')"
            LRM_SUITE="$2"
            shift 2
            ;;
        -h|--help) usage; exit 0 ;;
        -e|--everything|-E|--epel|-r|--releasever|--arch|--appstream|--crb|--powertools|--no-epel|--no-appstream|--no-crb|--no-baseos)
            die "$(printf "$(_ 'option %s is only supported on RPM-based systems')" "$1")"
            ;;
        -n|--count|-W|--timeout|--ref)
            die "$(printf "$(_ 'option %s belongs before the command name or on pingtest/bwtest')" "$1")"
            ;;
        -*) die "$(printf "$(_ 'unknown option: %s')" "$1")" ;;
        *)
            [[ -z "$PARSE_APPLY_TARGET" ]] || die "$(printf "$(_ 'unexpected argument: %s')" "$1")"
            PARSE_APPLY_TARGET="$1"
            shift
            ;;
        esac
    done

    [[ -n "$PARSE_APPLY_TARGET" ]] || die "$(_ 'usage: lrm use [-c|--config-only] [-a|--all] [-s|--src] [-u|--updates] [-b|--backports] [--security] ALIAS|NUM')"

    export LRM_CONFIG_ONLY LRM_SUITE LRM_DEB_SRC LRM_DEB_UPDATES LRM_DEB_BACKPORTS
    export LRM_DEB_SECURITY LRM_DEB_COMPONENTS
}

parse_sel_opts() {
    lrm_debian_apply_defaults
    LRM_CONFIG_ONLY=0
    PING_COUNT=3
    PING_TIMEOUT=2
    local suite="${LRM_SUITE:-$(detect_debian_suite)}"
    LRM_SUITE="$suite"

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -c|--config-only) LRM_CONFIG_ONLY=1; shift ;;
        -a|--all) lrm_debian_apply_defaults; shift ;;
        --minimal) lrm_debian_apply_minimal; shift ;;
        -s|--src) LRM_DEB_SRC=1; shift ;;
        --no-src) LRM_DEB_SRC=0; shift ;;
        -u|--updates) LRM_DEB_UPDATES=1; shift ;;
        --no-updates) LRM_DEB_UPDATES=0; shift ;;
        -b|--backports) LRM_DEB_BACKPORTS=1; shift ;;
        --no-backports) LRM_DEB_BACKPORTS=0; shift ;;
        --security) LRM_DEB_SECURITY=1; shift ;;
        --no-security) LRM_DEB_SECURITY=0; shift ;;
        --contrib|--non-free|--firmware)
            local flag="${1#--}"
            flag="${flag//-/_}"
            case "$flag" in
            non_free) LRM_DEB_COMPONENTS+=" non-free" ;;
            firmware) LRM_DEB_COMPONENTS+=" non-free-firmware" ;;
            contrib) LRM_DEB_COMPONENTS+=" contrib" ;;
            esac
            LRM_DEB_COMPONENTS="$(printf '%s\n' "$LRM_DEB_COMPONENTS" | tr ' ' '\n' | awk '!seen[$0]++' | tr '\n' ' ')"
            LRM_DEB_COMPONENTS="${LRM_DEB_COMPONENTS# }"
            LRM_DEB_COMPONENTS="${LRM_DEB_COMPONENTS% }"
            shift
            ;;
        --suite)
            [[ $# -ge 2 ]] || die "$(_ 'usage: --suite SUITE')"
            LRM_SUITE="$2"
            shift 2
            ;;
        -n|--count)
            [[ $# -ge 2 ]] || die "$(_ 'usage: -n|--count N')"
            PING_COUNT="$2"
            shift 2
            ;;
        -W|--timeout)
            [[ $# -ge 2 ]] || die "$(_ 'usage: -W|--timeout SEC')"
            PING_TIMEOUT="$2"
            shift 2
            ;;
        --ref)
            [[ $# -ge 2 ]] || die "$(_ 'usage: --ref BYTES')"
            BWTEST_REF_BYTES="$2"
            shift 2
            ;;
        -e|--everything|-E|--epel|-r|--releasever|--arch|--appstream|--crb|--powertools|--no-epel|--no-appstream|--no-crb|--no-baseos)
            die "$(printf "$(_ 'option %s is only supported on RPM-based systems')" "$1")"
            ;;
        -h|--help) usage; exit 0 ;;
        -*) die "$(printf "$(_ 'unknown option: %s')" "$1")" ;;
        *) die "$(printf "$(_ 'unexpected argument: %s')" "$1")" ;;
        esac
    done

    export LRM_CONFIG_ONLY LRM_SUITE LRM_DEB_SRC LRM_DEB_UPDATES LRM_DEB_BACKPORTS
    export LRM_DEB_SECURITY LRM_DEB_COMPONENTS PING_COUNT PING_TIMEOUT
    export BWTEST_REF_BYTES
}

mirror_probe_url() {
    local base="${1%/}"
    local suite="${LRM_SUITE:-$(detect_debian_suite)}"
    printf '%s/dists/%s/Release\n' "$base" "$suite"
}

_render_debian_stanza() {
    local types="$1"
    local uri="$2"
    local suites="$3"
    local components="$4"
    local outpath="$5"

    {
        printf 'Types: %s\n' "$types"
        printf 'URIs: %s\n' "$uri"
        printf 'Suites: %s\n' "$suites"
        printf 'Components: %s\n' "$components"
        printf '\n'
    } >>"$outpath"
}

render_mirror_config() {
    local url="${1%/}"
    local outpath="$2"
    local suite="${LRM_SUITE:-$(detect_debian_suite)}"
    local components="${LRM_DEB_COMPONENTS:-main contrib non-free non-free-firmware}"
    local types="deb"
    local -a suites=("$suite")
    local suites_str sec_url

    if [[ "${LRM_DEB_SRC:-0}" -eq 1 ]]; then
        types="deb deb-src"
    fi
    if [[ "${LRM_DEB_UPDATES:-0}" -eq 1 ]]; then
        suites+=("${suite}-updates")
    fi
    if [[ "${LRM_DEB_BACKPORTS:-0}" -eq 1 ]]; then
        suites+=("${suite}-backports")
    fi
    suites_str="${suites[*]}"

    cat >"$outpath" <<EOF
# Managed by lrm — do not edit by hand.
EOF

    _render_debian_stanza "$types" "$url" "$suites_str" "$components" "$outpath"

    if [[ "${LRM_DEB_SECURITY:-0}" -eq 1 ]]; then
        sec_url="$(debian_security_mirror_url "$url")"
        _render_debian_stanza "$types" "$sec_url" "${suite}-security" "$components" "$outpath"
    fi
}

refresh_apt_metadata() {
    if [[ "${LRM_CONFIG_ONLY:-0}" -eq 1 ]]; then
        vlog2 "skipping apt-get update (--config-only)"
        return 0
    fi
    command -v apt-get >/dev/null 2>&1 || return 0

    local -a cmd
    if command -v timeout >/dev/null 2>&1; then
        cmd=(timeout 120 apt-get update)
    else
        cmd=(apt-get update)
    fi

    if [[ "$(id -u)" -eq 0 ]]; then
        vlog2 "running apt-get update as root"
        "${cmd[@]}" >/dev/null 2>&1 || warn "$(_ 'warning: apt-get update failed')"
    elif command -v sudo >/dev/null 2>&1; then
        vlog2 "running apt-get update via sudo"
        sudo "${cmd[@]}" >/dev/null 2>&1 || warn "$(_ 'warning: apt-get update failed')"
    else
        vlog2 "skipping apt-get update (not root and no sudo)"
    fi
}

apply_mirror() {
    local url="${1%/}"
    local path="/etc/apt/sources.list.d/lrm.sources"
    local legacy="/etc/apt/sources.list.d/lrm.list"
    local tmp

    vlog2 "applying apt mirror $url to $path (suite=${LRM_SUITE:-$(detect_debian_suite)} components=${LRM_DEB_COMPONENTS:-main})"
    tmp="$(mktemp "${TMPDIR:-/tmp}/lrm-sources.XXXXXX")"
    render_mirror_config "$url" "$tmp"
    install_as_root "$tmp" "$path"
    rm -f "$tmp"

    if [[ -f "$legacy" ]]; then
        remove_privileged "$legacy"
        vlog "removed legacy $legacy"
    fi

    refresh_apt_metadata
    log "$(printf "$(_ 'wrote %s')" "$path")"
}
