#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

root="${1:?source root}"
build="${2:-$root/build}"
po="$root/po"

cd "$root"
mapfile -t sources < <(grep -v '^[[:space:]]*#' "$po/POTFILES" | grep -v '^[[:space:]]*$')

xgettext --from-code=UTF-8 \
    --language=Shell \
    --add-comments=TRANSLATORS: \
    --keyword=_ \
    --keyword=ngettext:1,2 \
    --keyword=die:1c-format \
    --keyword=warn:1c-format \
    --package-name=lrm \
    --package-version="$(meson introspect --projectinfo "$build" 2>/dev/null | sed -n 's/.*"version": "\([^"]*\)".*/\1/p' | head -1 || echo 0.0.0)" \
    --output="$po/lrm.pot" \
    "${sources[@]}"

while IFS= read -r lang || [[ -n "$lang" ]]; do
    [[ -z "$lang" || "$lang" =~ ^# ]] && continue
    if [[ ! -f "$po/$lang.po" ]]; then
        msginit --no-translator --input="$po/lrm.pot" --locale="$lang" --output="$po/$lang.po"
    fi
    msgmerge --update --no-fuzzy-matching --previous "$po/$lang.po" "$po/lrm.pot"
done <"$po/LINGUAS"
