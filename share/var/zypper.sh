#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# openSUSE / SLES backend (zypper). China-friendly mirrors under /opensuse/.
# SLES suites map onto openSUSE Leap / distribution trees so builds do not
# require an SCC subscription.

detect_zypper_release() {
    if [[ -n "${LRM_RELEASE:-}" ]]; then
        printf '%s\n' "$LRM_RELEASE"
        return 0
    fi
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        if [[ -n "${VERSION_ID:-}" ]]; then
            printf '%s\n' "$VERSION_ID"
            return 0
        fi
    fi
    printf '%s\n' "15.6"
}

# Map sles:N (and opensuse:N) onto the openSUSE tree used for free mirrors.
sles_to_opensuse_rel() {
    local rel="${1:-}"
    case "$rel" in
    11|11.*) printf '13.2\n' ;;
    12|12.*) printf '42.3\n' ;;
    15.1) printf '15.1\n' ;;
    15|15.*) printf '%s\n' "$rel" ;;
    16|16.*) printf '16.0\n' ;;
    *) printf '%s\n' "$rel" ;;
    esac
}

opensuse_oss_path() {
    local leap="$1"
    case "$leap" in
    13.*) printf 'distribution/%s/repo/oss/\n' "$leap" ;;
    42.*) printf 'distribution/leap/%s/repo/oss/\n' "$leap" ;;
    *)    printf 'distribution/leap/%s/repo/oss/\n' "$leap" ;;
    esac
}

opensuse_update_path() {
    local leap="$1"
    case "$leap" in
    13.*) printf 'update/%s/\n' "$leap" ;;
    42.*) printf 'update/leap/%s/oss/\n' "$leap" ;;
    *)    printf 'update/leap/%s/oss/\n' "$leap" ;;
    esac
}

_zypper_append_repo() {
    local id="$1"
    local name="$2"
    local baseurl="$3"
    local outpath="$4"

    {
        printf '[%s]\n' "$id"
        printf 'name=%s\n' "$name"
        printf 'enabled=1\n'
        printf 'autorefresh=1\n'
        printf 'baseurl=%s\n' "$baseurl"
        printf 'type=rpm-md\n'
        printf 'gpgcheck=0\n'
        printf 'keeppackages=1\n'
        printf '\n'
    } >>"$outpath"
}

mirror_probe_url() {
    local base="${1%/}"
    local release rel path
    release="${LRM_ZYPPER_RELEASE:-$(detect_zypper_release)}"
    rel="$(sles_to_opensuse_rel "$release")"
    path="$(opensuse_oss_path "$rel")"
    printf '%s/%srepodata/repomd.xml\n' "$base" "$path"
}

render_mirror_config() {
    local url="${1%/}"
    local outpath="$2"
    local release rel oss upd

    release="${LRM_ZYPPER_RELEASE:-$(detect_zypper_release)}"
    rel="$(sles_to_opensuse_rel "$release")"
    oss="$(opensuse_oss_path "$rel")"
    upd="$(opensuse_update_path "$rel")"

    : >"$outpath"
    printf '# Managed by lrm — do not edit by hand.\n\n' >>"$outpath"
    _zypper_append_repo lrm-oss "lrm openSUSE OSS ($rel)" "$url/$oss" "$outpath"
    _zypper_append_repo lrm-update "lrm openSUSE Update ($rel)" "$url/$upd" "$outpath"
}

apply_mirror() {
    local url="${1%/}"
    local path="/etc/zypp/repos.d/lrm.repo"
    local tmp

    vlog2 "applying zypper mirror $url to $path (release=${LRM_ZYPPER_RELEASE:-$(detect_zypper_release)})"
    tmp="$(mktemp "${TMPDIR:-/tmp}/lrm-zypp.XXXXXX")"
    render_mirror_config "$url" "$tmp"
    install_as_root "$tmp" "$path"
    rm -f "$tmp"

    run_as_root rm -f /etc/zypp/repos.d/lrm-bootstrap.repo 2>/dev/null || true

    if [[ "${LRM_CONFIG_ONLY:-0}" -eq 1 ]]; then
        vlog2 "skipping zypper refresh (--config-only)"
    elif command -v zypper >/dev/null 2>&1; then
        run_as_root zypper --non-interactive --gpg-auto-import-keys refresh >/dev/null 2>&1 || true
    fi
    log "$(printf "$(_ 'wrote %s')" "$path")"
}

_zypper_parse_apply_flags() {
    case "$1" in
    -c|--config-only) LRM_CONFIG_ONLY=1 ;;
    -a|--all|-e|--everything|--minimal) ;;
    *) return 1 ;;
    esac
}

parse_apply_opts() {
    LRM_CONFIG_ONLY=0
    LRM_ZYPPER_RELEASE="$(detect_zypper_release)"
    PARSE_APPLY_TARGET=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -c|--config-only|-a|--all|-e|--everything|--minimal)
            _zypper_parse_apply_flags "$1"
            shift
            ;;
        --releasever|-r)
            [[ $# -ge 2 ]] || die "$(_ 'usage: --releasever VER')"
            LRM_ZYPPER_RELEASE="$2"
            shift 2
            ;;
        -s|--src|-u|--updates|-b|--backports|--security|--no-src|--no-updates|--no-backports|--no-security|--contrib|--non-free|--firmware|--suite|--epel|-E|--baseos|--appstream|--crb|--powertools)
            die "$(printf "$(_ 'option %s is not supported on SUSE/openSUSE systems')" "$1")"
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

    [[ -n "$PARSE_APPLY_TARGET" ]] || die "$(_ 'usage: lrm use [-c|--config-only] [--releasever VER] ALIAS|NUM')"
    export LRM_CONFIG_ONLY LRM_ZYPPER_RELEASE
}

parse_sel_opts() {
    LRM_CONFIG_ONLY=0
    PING_COUNT=3
    PING_TIMEOUT=2
    LRM_ZYPPER_RELEASE="$(detect_zypper_release)"

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -c|--config-only|-a|--all|-e|--everything|--minimal)
            _zypper_parse_apply_flags "$1"
            shift
            ;;
        --releasever|-r)
            [[ $# -ge 2 ]] || die "$(_ 'usage: --releasever VER')"
            LRM_ZYPPER_RELEASE="$2"
            shift 2
            ;;
        -s|--src|-u|--updates|-b|--backports|--security|--no-src|--no-updates|--no-backports|--no-security|--contrib|--non-free|--firmware|--suite|--epel|-E|--baseos|--appstream|--crb|--powertools)
            die "$(printf "$(_ 'option %s is not supported on SUSE/openSUSE systems')" "$1")"
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

    export LRM_CONFIG_ONLY LRM_ZYPPER_RELEASE
    export PING_COUNT PING_TIMEOUT BWTEST_REF_BYTES
}
