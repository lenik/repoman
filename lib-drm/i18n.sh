#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later

DRM_TEXTDOMAIN="${DRM_TEXTDOMAIN:-@DRM_TEXTDOMAIN@}"
DRM_INSTALL_LOCALEDIR="${DRM_INSTALL_LOCALEDIR:-@DRM_INSTALL_LOCALEDIR@}"
DRM_SOURCE_LOCALEDIR="${DRM_SOURCE_LOCALEDIR:-@DRM_SOURCE_LOCALEDIR@}"
DRM_BUILD_LOCALEDIR="${DRM_BUILD_LOCALEDIR:-@DRM_BUILD_LOCALEDIR@}"

_i18n_lang_code() {
    local lang="${LANGUAGE:-${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}}"
    lang="${lang%%.*}"
    lang="${lang%%@*}"
    printf '%s\n' "$lang"
}

_find_textdomain_root() {
    local lang="$1"
    local domain="$DRM_TEXTDOMAIN" root
    for root in "$DRM_SOURCE_LOCALEDIR" "$DRM_BUILD_LOCALEDIR" "$DRM_INSTALL_LOCALEDIR"; do
        [[ -n "$root" && "$root" != @*@ && -f "$root/$lang/LC_MESSAGES/$domain.mo" ]] || continue
        printf '%s\n' "$root"
        return 0
    done
    return 1
}

init_i18n() {
    export TEXTDOMAIN="$DRM_TEXTDOMAIN"
    local lang root
    lang="$(_i18n_lang_code)"
    if root="$(_find_textdomain_root "$lang")"; then
        export TEXTDOMAINDIR="$root"
        return 0
    fi
    if [[ -n "$DRM_INSTALL_LOCALEDIR" && "$DRM_INSTALL_LOCALEDIR" != @*@ ]]; then
        export TEXTDOMAINDIR="$DRM_INSTALL_LOCALEDIR"
    fi
}

# shellcheck disable=SC2317
_() {
    if declare -F gettext >/dev/null 2>&1; then
        gettext "$@"
        return
    fi
    if command -v gettext >/dev/null 2>&1; then
        gettext -d "$TEXTDOMAIN" "$@"
        return
    fi
    printf '%s' "$*"
}

if [[ -f /usr/share/gettext/gettext.sh ]]; then
    # shellcheck source=/dev/null
    . /usr/share/gettext/gettext.sh
    export TEXTDOMAIN
fi

init_i18n
