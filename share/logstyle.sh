#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later

# Caller must set TOOL_NAME (e.g. lrm, drm) before sourcing.

init_log_colors() {
    LOG_USE_COLOR=0
    C_RESET=''
    C_LABEL=''
    C_LOG0=''
    C_LOG1=''
    C_LOG2=''
    C_LOG3=''
    C_LOG4=''
    C_WARN=''
    C_ERR=''

    [[ -t 2 ]] || return 0
    [[ -n "${TERM:-}" && "${TERM:-}" != dumb ]] || return 0

    if command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
        local ncolors
        ncolors="$(tput colors 2>/dev/null || printf '0')"
        if [[ "$ncolors" -ge 8 ]]; then
            LOG_USE_COLOR=1
            C_RESET="$(tput sgr0 2>/dev/null || true)"
            C_LABEL="$(tput bold 2>/dev/null)$(tput setaf 7 2>/dev/null || true)"
            C_LOG0="$(tput setaf 2 2>/dev/null || true)"
            C_LOG1="$(tput setaf 6 2>/dev/null || true)"
            C_LOG2="$(tput setaf 4 2>/dev/null || true)"
            C_LOG3="$(tput setaf 5 2>/dev/null || true)"
            C_LOG4="$(tput setaf 8 2>/dev/null || true)"
            C_WARN="$(tput setaf 3 2>/dev/null || true)"
            C_ERR="$(tput bold 2>/dev/null)$(tput setaf 1 2>/dev/null || true)"
            return 0
        fi
    fi

    LOG_USE_COLOR=1
    C_RESET=$'\033[0m'
    C_LABEL=$'\033[1;37m'
    C_LOG0=$'\033[32m'
    C_LOG1=$'\033[36m'
    C_LOG2=$'\033[34m'
    C_LOG3=$'\033[35m'
    C_LOG4=$'\033[90m'
    C_WARN=$'\033[33m'
    C_ERR=$'\033[1;31m'
}

_log_color_for_level() {
    case "$1" in
    0) printf '%s' "${C_LOG0}" ;;
    1) printf '%s' "${C_LOG1}" ;;
    2) printf '%s' "${C_LOG2}" ;;
    3) printf '%s' "${C_LOG3}" ;;
    4) printf '%s' "${C_LOG4}" ;;
    warn) printf '%s' "${C_WARN}" ;;
    err) printf '%s' "${C_ERR}" ;;
    *) printf '%s' '' ;;
    esac
}

_log_emit() {
    local level="$1"
    shift
    local body color label
    local name="${TOOL_NAME:-repoman}"

    if [[ "${LOG_USE_COLOR:-0}" -eq 1 ]]; then
        color="$(_log_color_for_level "$level")"
        label="${C_LABEL}${name}:${C_RESET}${color}"
        body="$*${C_RESET}"
        printf '%s %s\n' "$label" "$body" >&2
        return 0
    fi
    printf '%s: %s\n' "$name" "$*" >&2
}

init_log_colors
