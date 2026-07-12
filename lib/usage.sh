#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later

usage() {
    cat <<EOF
$(_ 'Usage: lrm [OPTION]... COMMAND [ARGS]...')

$(_ 'Manage distribution package mirrors and select the fastest one.')

$(_ 'Options:')
$(_ '  -v, --verbose      more logging (repeatable: -v tests, -vv paths, -vvv metrics, -vvvv trace)')
$(_ '  -q, --quiet        less logging')
$(_ '  -o, --distro SPEC  target distribution[:release] (default: detect from host)')
$(_ '                     e.g. debian:bookworm, ubuntu:focal, centos:7')
$(_ '  -l, --list-distros list supported distribution names')
$(_ '  -h, --help         show this help')
$(_ '      --version      show version')

$(_ 'Commands:')
$(_ '  list [-c|--char] [-p|--priority]')
$(_ '                     list mirrors: MARK [N] ALIAS (emoji default; -c: * in use, x failed, + fastest, v ok, ? untested)')
$(_ '  add [[-PRIORITY] | -p|--priority N] ALIAS URL')
$(_ '                     add or update a mirror (default priority 100)')
$(_ '  remove ALIAS|NUM   remove a mirror')
$(_ '  use [-c|--config-only] [apply opts] ALIAS|NUM')
$(_ '                     Debian: [-a|--all] [-s|--src] [-u|--updates] [-b|--backports]')
$(_ '                     [--security] [--suite SUITE]')
$(_ '                     RPM: [-e|--everything] [-E|--epel] [-a|--all] [--releasever VER]')
$(_ '                     [--arch ARCH] [--appstream] [--crb|--powertools] [--minimal]')
$(_ '                     apply mirror (Debian default: all components; RPM default: BaseOS)')
$(_ '  pingtest [-n|--count N] [-W|--timeout SEC]')
$(_ '                     ping all mirrors; list by latency')
$(_ '  bwtest [--ref BYTES]')
$(_ '                     download test on all mirrors; list by score')
$(_ '  pingsel [apply opts] [-n|--count N] [-W|--timeout SEC]')
$(_ '                     pingtest then use the best mirror')
$(_ '  bwsel [apply opts] [--ref BYTES]')
$(_ '                     bwtest then use the best mirror')
$(_ '  help               show this help')
$(_ '  version            show version')
EOF
}
