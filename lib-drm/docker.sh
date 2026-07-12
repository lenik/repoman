#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later

DRM_DAEMON_JSON="${DRM_DAEMON_JSON:-/etc/docker/daemon.json}"

mirror_probe_url() {
    local base="${1%/}"
    printf '%s/v2/\n' "$base"
}

_docker_merge_daemon_json() {
    local mirror_url="$1"
    local outpath="$2"

    python3 - "$DRM_DAEMON_JSON" "$mirror_url" "$outpath" <<'PY'
import json
import os
import sys

src, mirror, out = sys.argv[1:4]
data = {}
if os.path.isfile(src):
    with open(src, encoding="utf-8") as fh:
        data = json.load(fh)
if not isinstance(data, dict):
    data = {}
data["registry-mirrors"] = [mirror]
with open(out, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
PY
}

reload_docker_daemon() {
    if [[ "${DRM_CONFIG_ONLY:-0}" -eq 1 ]]; then
        vlog2 "skipping docker daemon reload (--config-only)"
        return 0
    fi
    if command -v systemctl >/dev/null 2>&1; then
        run_as_root systemctl reload docker >/dev/null 2>&1 \
            || run_as_root systemctl restart docker >/dev/null 2>&1 \
            || warn "$(_ 'warning: could not reload docker via systemctl')"
        return 0
    fi
    warn "$(_ 'warning: systemctl not found; restart docker manually')"
}

apply_mirror() {
    local url="${1%/}"
    local backup="${DRM_DAEMON_JSON}.drm.bak"
    local tmp

    vlog2 "applying Docker registry mirror $url to $DRM_DAEMON_JSON"
    require_commands python3

    if [[ ! -f "$backup" && -f "$DRM_DAEMON_JSON" ]]; then
        elevated "$backup" cp -a "$DRM_DAEMON_JSON" "$backup"
    fi

    tmp="$(mktemp "${TMPDIR:-/tmp}/drm-daemon.XXXXXX")"
    _docker_merge_daemon_json "$url" "$tmp"
    install_as_root "$tmp" "$DRM_DAEMON_JSON"
    rm -f "$tmp"

    reload_docker_daemon
    log "$(printf "$(_ 'wrote %s')" "$DRM_DAEMON_JSON")"
}

parse_apply_opts() {
    DRM_CONFIG_ONLY=0
    PARSE_APPLY_TARGET=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -c|--config-only) DRM_CONFIG_ONLY=1; shift ;;
        -h|--help) usage; exit 0 ;;
        -*) die "$(printf "$(_ 'unknown option: %s')" "$1")" ;;
        *)
            [[ -z "$PARSE_APPLY_TARGET" ]] || die "$(printf "$(_ 'unexpected argument: %s')" "$1")"
            PARSE_APPLY_TARGET="$1"
            shift
            ;;
        esac
    done

    [[ -n "$PARSE_APPLY_TARGET" ]] || die "$(_ 'usage: drm use [-c|--config-only] ALIAS|NUM')"
    export DRM_CONFIG_ONLY
}

parse_sel_opts() {
    DRM_CONFIG_ONLY=0
    DRM_PING_COUNT=3
    DRM_PING_TIMEOUT=2

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -c|--config-only) DRM_CONFIG_ONLY=1; shift ;;
        -n|--count)
            [[ $# -ge 2 ]] || die "$(_ 'usage: -n|--count N')"
            DRM_PING_COUNT="$2"
            shift 2
            ;;
        -W|--timeout)
            [[ $# -ge 2 ]] || die "$(_ 'usage: -W|--timeout SEC')"
            DRM_PING_TIMEOUT="$2"
            shift 2
            ;;
        --ref)
            [[ $# -ge 2 ]] || die "$(_ 'usage: --ref BYTES')"
            DRM_BWTEST_REF_BYTES="$2"
            shift 2
            ;;
        -h|--help) usage; exit 0 ;;
        -*) die "$(printf "$(_ 'unknown option: %s')" "$1")" ;;
        *) die "$(printf "$(_ 'unexpected argument: %s')" "$1")" ;;
        esac
    done

    export DRM_CONFIG_ONLY DRM_PING_COUNT DRM_PING_TIMEOUT DRM_BWTEST_REF_BYTES
}
