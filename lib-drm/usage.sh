#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later

usage() {
    cat <<EOF
$(_ 'Usage: drm [OPTION]... COMMAND [ARGS]...')

$(_ 'Manage Docker registry mirrors and select the fastest one.')

$(_ 'Options:')
$(_ '  -v, --verbose      more logging (repeatable: -v tests, -vv paths, -vvv metrics, -vvvv trace)')
$(_ '  -q, --quiet        less logging')
$(_ '  -h, --help         show this help')
$(_ '      --version      show version')

$(_ 'Commands:')
$(_ '  list [-c|--char] [-p|--priority]')
$(_ '                     list mirrors: MARK [N] ALIAS (emoji default; -c: * in use, x failed, + fastest, v ok, ? untested)')
$(_ '  add [[-PRIORITY] | -p|--priority N] ALIAS URL')
$(_ '                     add or update a registry mirror (default priority 100)')
$(_ '  remove ALIAS|NUM   remove a mirror')
$(_ '  use [-c|--config-only] ALIAS|NUM')
$(_ '                     set registry-mirrors in /etc/docker/daemon.json')
$(_ '  pingtest [-n|--count N] [-W|--timeout SEC]')
$(_ '                     ping all mirrors; list by latency')
$(_ '  bwtest [--ref BYTES]')
$(_ '                     download test on all mirrors; list by score')
$(_ '  pingsel [-c|--config-only] [-n|--count N] [-W|--timeout SEC]')
$(_ '                     pingtest then use the best mirror')
$(_ '  bwsel [-c|--config-only] [--ref BYTES]')
$(_ '                     bwtest then use the best mirror')
$(_ '  help               show this help')
$(_ '  version            show version')
EOF
}
