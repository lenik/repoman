#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later

init_log_colors() {
    DRM_LOG_USE_COLOR=0
    DRM_C_RESET=''
    DRM_C_LABEL=''
    DRM_C_LOG0=''
    DRM_C_LOG1=''
    DRM_C_LOG2=''
    DRM_C_LOG3=''
    DRM_C_LOG4=''
    DRM_C_WARN=''
    DRM_C_ERR=''

    [[ -t 2 ]] || return 0
    [[ -n "${TERM:-}" && "${TERM:-}" != dumb ]] || return 0

    if command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
        local ncolors
        ncolors="$(tput colors 2>/dev/null || printf '0')"
        if [[ "$ncolors" -ge 8 ]]; then
            DRM_LOG_USE_COLOR=1
            DRM_C_RESET="$(tput sgr0 2>/dev/null || true)"
            DRM_C_LABEL="$(tput bold 2>/dev/null)$(tput setaf 7 2>/dev/null || true)"
            DRM_C_LOG0="$(tput setaf 2 2>/dev/null || true)"
            DRM_C_LOG1="$(tput setaf 6 2>/dev/null || true)"
            DRM_C_LOG2="$(tput setaf 4 2>/dev/null || true)"
            DRM_C_LOG3="$(tput setaf 5 2>/dev/null || true)"
            DRM_C_LOG4="$(tput setaf 8 2>/dev/null || true)"
            DRM_C_WARN="$(tput setaf 3 2>/dev/null || true)"
            DRM_C_ERR="$(tput bold 2>/dev/null)$(tput setaf 1 2>/dev/null || true)"
            return 0
        fi
    fi

    DRM_LOG_USE_COLOR=1
    DRM_C_RESET=$'\033[0m'
    DRM_C_LABEL=$'\033[1;37m'
    DRM_C_LOG0=$'\033[32m'
    DRM_C_LOG1=$'\033[36m'
    DRM_C_LOG2=$'\033[34m'
    DRM_C_LOG3=$'\033[35m'
    DRM_C_LOG4=$'\033[90m'
    DRM_C_WARN=$'\033[33m'
    DRM_C_ERR=$'\033[1;31m'
}

_log_color_for_level() {
    case "$1" in
    0) printf '%s' "${DRM_C_LOG0}" ;;
    1) printf '%s' "${DRM_C_LOG1}" ;;
    2) printf '%s' "${DRM_C_LOG2}" ;;
    3) printf '%s' "${DRM_C_LOG3}" ;;
    4) printf '%s' "${DRM_C_LOG4}" ;;
    warn) printf '%s' "${DRM_C_WARN}" ;;
    err) printf '%s' "${DRM_C_ERR}" ;;
    *) printf '%s' '' ;;
    esac
}

_log_emit() {
    local level="$1"
    shift
    local body color label

    if [[ "${DRM_LOG_USE_COLOR:-0}" -eq 1 ]]; then
        color="$(_log_color_for_level "$level")"
        label="${DRM_C_LABEL}drm:${DRM_C_RESET}${color}"
        body="$*${DRM_C_RESET}"
        printf '%s %s\n' "$label" "$body" >&2
        return 0
    fi
    printf 'drm: %s\n' "$*" >&2
}

init_log_colors
