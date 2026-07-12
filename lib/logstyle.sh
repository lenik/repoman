#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later

init_log_colors() {
    LRM_LOG_USE_COLOR=0
    LRM_C_RESET=''
    LRM_C_LABEL=''
    LRM_C_LOG0=''
    LRM_C_LOG1=''
    LRM_C_LOG2=''
    LRM_C_LOG3=''
    LRM_C_LOG4=''
    LRM_C_WARN=''
    LRM_C_ERR=''

    [[ -t 2 ]] || return 0
    [[ -n "${TERM:-}" && "${TERM:-}" != dumb ]] || return 0

    if command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
        local ncolors
        ncolors="$(tput colors 2>/dev/null || printf '0')"
        if [[ "$ncolors" -ge 8 ]]; then
            LRM_LOG_USE_COLOR=1
            LRM_C_RESET="$(tput sgr0 2>/dev/null || true)"
            LRM_C_LABEL="$(tput bold 2>/dev/null)$(tput setaf 7 2>/dev/null || true)"
            LRM_C_LOG0="$(tput setaf 2 2>/dev/null || true)"
            LRM_C_LOG1="$(tput setaf 6 2>/dev/null || true)"
            LRM_C_LOG2="$(tput setaf 4 2>/dev/null || true)"
            LRM_C_LOG3="$(tput setaf 5 2>/dev/null || true)"
            LRM_C_LOG4="$(tput setaf 8 2>/dev/null || true)"
            LRM_C_WARN="$(tput setaf 3 2>/dev/null || true)"
            LRM_C_ERR="$(tput bold 2>/dev/null)$(tput setaf 1 2>/dev/null || true)"
            return 0
        fi
    fi

    LRM_LOG_USE_COLOR=1
    LRM_C_RESET=$'\033[0m'
    LRM_C_LABEL=$'\033[1;37m'
    LRM_C_LOG0=$'\033[32m'
    LRM_C_LOG1=$'\033[36m'
    LRM_C_LOG2=$'\033[34m'
    LRM_C_LOG3=$'\033[35m'
    LRM_C_LOG4=$'\033[90m'
    LRM_C_WARN=$'\033[33m'
    LRM_C_ERR=$'\033[1;31m'
}

_log_color_for_level() {
    case "$1" in
    0) printf '%s' "${LRM_C_LOG0}" ;;
    1) printf '%s' "${LRM_C_LOG1}" ;;
    2) printf '%s' "${LRM_C_LOG2}" ;;
    3) printf '%s' "${LRM_C_LOG3}" ;;
    4) printf '%s' "${LRM_C_LOG4}" ;;
    warn) printf '%s' "${LRM_C_WARN}" ;;
    err) printf '%s' "${LRM_C_ERR}" ;;
    *) printf '%s' '' ;;
    esac
}

_log_emit() {
    local level="$1"
    shift
    local body color label

    if [[ "${LRM_LOG_USE_COLOR:-0}" -eq 1 ]]; then
        color="$(_log_color_for_level "$level")"
        label="${LRM_C_LABEL}lrm:${LRM_C_RESET}${color}"
        body="$*${LRM_C_RESET}"
        printf '%s %s\n' "$label" "$body" >&2
        return 0
    fi
    printf 'lrm: %s\n' "$*" >&2
}

init_log_colors
