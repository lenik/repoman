#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later

detect_rpm_releasever() {
    if [[ -n "${LRM_RELEASE:-}" ]]; then
        printf '%s\n' "${LRM_RELEASE%%.*}"
        return 0
    fi
    if [[ -n "${LRM_RELEASEVER:-}" ]]; then
        printf '%s\n' "${LRM_RELEASEVER%%.*}"
        return 0
    fi
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        if [[ -n "${VERSION_ID:-}" ]]; then
            printf '%s\n' "${VERSION_ID%%.*}"
            return 0
        fi
    fi
    printf '%s\n' "9"
}

detect_rpm_basearch() {
    local arch
    arch="$(uname -m 2>/dev/null || true)"
    case "$arch" in
    x86_64|aarch64|ppc64le|s390x) printf '%s\n' "$arch" ; return 0 ;;
    esac
    printf '%s\n' "${LRM_ARCH:-x86_64}"
}

rpm_crb_repo_name() {
    local releasever="${1:-9}"
    releasever="${releasever%%.*}"
    if [[ "$releasever" -lt 9 ]]; then
        printf 'PowerTools\n'
    else
        printf 'CRB\n'
    fi
}

rpm_epel_mirror_url() {
    local url="${1%/}"
    if [[ "$url" == *rockylinux.org* || "$url" == *fedoraproject.org* ]]; then
        printf '%s\n' 'https://dl.fedoraproject.org/pub/epel'
        return 0
    fi
    if [[ "$url" =~ ^(https?://[^/]+) ]]; then
        printf '%s/epel\n' "${BASH_REMATCH[1]}"
        return 0
    fi
    printf '%s\n' "$url"
}

lrm_rpm_apply_minimal() {
    LRM_RPM_BASEOS=1
    LRM_RPM_APPSTREAM=0
    LRM_RPM_CRB=0
    LRM_RPM_EPEL=0
}

lrm_rpm_apply_defaults() {
    LRM_RPM_BASEOS=1
    LRM_RPM_APPSTREAM=1
    LRM_RPM_CRB=0
    LRM_RPM_EPEL=0
}

lrm_rpm_apply_everything() {
    LRM_RPM_BASEOS=1
    LRM_RPM_APPSTREAM=1
    LRM_RPM_CRB=1
    LRM_RPM_EPEL=0
}

lrm_rpm_apply_all() {
    lrm_rpm_apply_everything
    LRM_RPM_EPEL=1
}

_rpm_append_repo() {
    local id="$1"
    local name="$2"
    local baseurl="$3"
    local outpath="$4"

    {
        printf '[%s]\n' "$id"
        printf 'name=%s\n' "$name"
        printf 'baseurl=%s\n' "$baseurl"
        printf 'enabled=1\n'
        printf 'gpgcheck=0\n'
        printf 'skip_if_unavailable=1\n'
        printf '\n'
    } >>"$outpath"
}

mirror_probe_url() {
    local base="${1%/}"
    local releasever="${LRM_RELEASEVER:-$(detect_rpm_releasever)}"
    local basearch="${LRM_ARCH:-$(detect_rpm_basearch)}"
    local profile
    profile="$(distro_seed_profile "${LRM_DISTRO:-rpm}")"

    case "$profile" in
    fedora)
        printf '%s/releases/%s/Everything/%s/os/repodata/repomd.xml\n' \
            "$base" "$releasever" "$basearch"
        ;;
    openeuler)
        printf '%s/openEuler-%s-LTS/OS/%s/repodata/repomd.xml\n' \
            "$base" "$releasever" "$basearch"
        ;;
    centos)
        if centos_release_vault "${LRM_RELEASEVER:-$(detect_rpm_releasever)}"; then
            releasever="${LRM_RELEASEVER:-$(detect_rpm_releasever)}"
            releasever="${releasever%%.*}"
            case "$releasever" in
            7)
                printf '%s/7.9.2009/os/%s/repodata/repomd.xml\n' \
                    "$base" "$basearch"
                ;;
            8)
                printf '%s/8-stream/BaseOS/%s/os/repodata/repomd.xml\n' \
                    "$base" "$basearch"
                ;;
            *)
                printf '%s/%s/os/%s/repodata/repomd.xml\n' \
                    "$base" "$releasever" "$basearch"
                ;;
            esac
        else
            printf '%s/%s-stream/BaseOS/%s/os/repodata/repomd.xml\n' \
                "$base" "$releasever" "$basearch"
        fi
        ;;
    ol)
        printf '%s/OL%s/%s/baseos/%s/repodata/repomd.xml\n' \
            "$base" "$releasever" "$releasever" "$basearch"
        ;;
    alinux)
        printf '%s/alinux/%s/os/%s/repodata/repomd.xml\n' \
            "$base" "$releasever" "$basearch"
        ;;
    *)
        printf '%s/%s/BaseOS/%s/os/repodata/repomd.xml\n' \
            "$base" "$releasever" "$basearch"
        ;;
    esac
}

render_mirror_config() {
    local url="${1%/}"
    local outpath="$2"
    local releasever="${LRM_RELEASEVER:-$(detect_rpm_releasever)}"
    local basearch="${LRM_ARCH:-$(detect_rpm_basearch)}"
    local crb_repo epel_url

    crb_repo="$(rpm_crb_repo_name "$releasever")"
    : >"$outpath"
    printf '# Managed by lrm — do not edit by hand.\n\n' >>"$outpath"

    if [[ "${LRM_RPM_BASEOS:-1}" -eq 1 ]]; then
        _rpm_append_repo \
            lrm-baseos \
            'lrm BaseOS' \
            "$url/$releasever/BaseOS/$basearch/os/" \
            "$outpath"
    fi
    if [[ "${LRM_RPM_APPSTREAM:-0}" -eq 1 ]]; then
        _rpm_append_repo \
            lrm-appstream \
            'lrm AppStream' \
            "$url/$releasever/AppStream/$basearch/os/" \
            "$outpath"
    fi
    if [[ "${LRM_RPM_CRB:-0}" -eq 1 ]]; then
        _rpm_append_repo \
            "lrm-${crb_repo,,}" \
            "lrm $crb_repo" \
            "$url/$releasever/$crb_repo/$basearch/os/" \
            "$outpath"
    fi
    if [[ "${LRM_RPM_EPEL:-0}" -eq 1 ]]; then
        epel_url="$(rpm_epel_mirror_url "$url")"
        _rpm_append_repo \
            lrm-epel \
            'lrm EPEL' \
            "$epel_url/$releasever/Everything/$basearch/" \
            "$outpath"
    fi
}

apply_mirror() {
    local url="${1%/}"
    local path="/etc/yum.repos.d/lrm.repo"
    local tmp

    vlog2 "applying dnf/yum mirror $url to $path (releasever=${LRM_RELEASEVER:-$(detect_rpm_releasever)} arch=${LRM_ARCH:-$(detect_rpm_basearch)} baseos=${LRM_RPM_BASEOS:-1} appstream=${LRM_RPM_APPSTREAM:-0} crb=${LRM_RPM_CRB:-0} epel=${LRM_RPM_EPEL:-0})"
    tmp="$(mktemp "${TMPDIR:-/tmp}/lrm-repo.XXXXXX")"
    render_mirror_config "$url" "$tmp"
    install_as_root "$tmp" "$path"
    rm -f "$tmp"

    if [[ "${LRM_CONFIG_ONLY:-0}" -eq 1 ]]; then
        vlog2 "skipping dnf/yum metadata refresh (--config-only)"
    elif command -v dnf >/dev/null 2>&1; then
        run_as_root dnf clean metadata >/dev/null 2>&1 || true
    elif command -v yum >/dev/null 2>&1; then
        run_as_root yum clean metadata >/dev/null 2>&1 || true
    fi
    log "$(printf "$(_ 'wrote %s')" "$path")"
}

_rpm_parse_apply_flags() {
    case "$1" in
    -c|--config-only) LRM_CONFIG_ONLY=1 ;;
    -a|--all) lrm_rpm_apply_all ;;
    -e|--everything) lrm_rpm_apply_everything ;;
    -E|--epel) LRM_RPM_EPEL=1 ;;
    --minimal) lrm_rpm_apply_minimal ;;
    --baseos) LRM_RPM_BASEOS=1 ;;
    --no-baseos) LRM_RPM_BASEOS=0 ;;
    --appstream) LRM_RPM_APPSTREAM=1 ;;
    --no-appstream) LRM_RPM_APPSTREAM=0 ;;
    --crb|--powertools) LRM_RPM_CRB=1 ;;
    --no-crb) LRM_RPM_CRB=0 ;;
    --no-epel) LRM_RPM_EPEL=0 ;;
    *) return 1 ;;
    esac
}

parse_apply_opts() {
    lrm_rpm_apply_minimal
    LRM_CONFIG_ONLY=0
    LRM_RELEASEVER="$(detect_rpm_releasever)"
    LRM_ARCH="$(detect_rpm_basearch)"
    PARSE_APPLY_TARGET=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -c|--config-only|-a|--all|-e|--everything|-E|--epel|--minimal|--baseos|--no-baseos|--appstream|--no-appstream|--crb|--powertools|--no-crb|--no-epel)
            _rpm_parse_apply_flags "$1"
            shift
            ;;
        --releasever|-r)
            [[ $# -ge 2 ]] || die "$(_ 'usage: --releasever VER')"
            LRM_RELEASEVER="$2"
            shift 2
            ;;
        --arch)
            [[ $# -ge 2 ]] || die "$(_ 'usage: --arch ARCH')"
            LRM_ARCH="$2"
            shift 2
            ;;
        -s|--src|-u|--updates|-b|--backports|--security|--no-src|--no-updates|--no-backports|--no-security|--contrib|--non-free|--firmware|--suite)
            die "$(printf "$(_ 'option %s is only supported on Debian-based systems')" "$1")"
            ;;
        -h|--help) usage; exit 0 ;;
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

    [[ -n "$PARSE_APPLY_TARGET" ]] || die "$(_ 'usage: lrm use [-c|--config-only] [-e|--everything] [-E|--epel] [-a|--all] [--releasever VER] ALIAS|NUM')"

    export LRM_CONFIG_ONLY LRM_RELEASEVER LRM_ARCH
    export LRM_RPM_BASEOS LRM_RPM_APPSTREAM LRM_RPM_CRB LRM_RPM_EPEL
}

parse_sel_opts() {
    lrm_rpm_apply_minimal
    LRM_CONFIG_ONLY=0
    PING_COUNT=3
    PING_TIMEOUT=2
    LRM_RELEASEVER="$(detect_rpm_releasever)"
    LRM_ARCH="$(detect_rpm_basearch)"

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -c|--config-only|-a|--all|-e|--everything|-E|--epel|--minimal|--baseos|--no-baseos|--appstream|--no-appstream|--crb|--powertools|--no-crb|--no-epel)
            _rpm_parse_apply_flags "$1"
            shift
            ;;
        --releasever|-r)
            [[ $# -ge 2 ]] || die "$(_ 'usage: --releasever VER')"
            LRM_RELEASEVER="$2"
            shift 2
            ;;
        --arch)
            [[ $# -ge 2 ]] || die "$(_ 'usage: --arch ARCH')"
            LRM_ARCH="$2"
            shift 2
            ;;
        -s|--src|-u|--updates|-b|--backports|--security|--no-src|--no-updates|--no-backports|--no-security|--contrib|--non-free|--firmware|--suite)
            die "$(printf "$(_ 'option %s is only supported on Debian-based systems')" "$1")"
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
        -h|--help) usage; exit 0 ;;
        -*) die "$(printf "$(_ 'unknown option: %s')" "$1")" ;;
        *) die "$(printf "$(_ 'unexpected argument: %s')" "$1")" ;;
        esac
    done

    export LRM_CONFIG_ONLY LRM_RELEASEVER LRM_ARCH
    export LRM_RPM_BASEOS LRM_RPM_APPSTREAM LRM_RPM_CRB LRM_RPM_EPEL
    export PING_COUNT PING_TIMEOUT BWTEST_REF_BYTES
}
