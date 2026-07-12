#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later

MIRROR_ALIASES=()
MIRROR_PRIORITIES=()
MIRROR_URLS=()

LRM_MIRROR_FILE=""
LRM_DEFAULT_FILE=""
LRM_HEALTH_FILE=""
DISTRO_FAMILY=""
LRM_GETBAR="${LRM_GETBAR:-getbar}"
LRM_GETBAR_OPTS="${LRM_GETBAR_OPTS:--c -d2 -p1 -w3 -s30m -i.1 -q}"
# Reference download size for scoring: effective B/s = ref / (offset + ref/bps).
LRM_BWTEST_REF_BYTES="${LRM_BWTEST_REF_BYTES:-3000000}"

# Logging levels (set VERBOSE via -v / -vv / ...):
#   0  normal progress and warnings
#   1  per-mirror test activity
#   2  paths, distro detection, privilege elevation
#   3  per-mirror measurements and commands
#   4  external tool output and trace detail
log() {
    local level=0
    if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
        level="$1"
        shift
    fi
    [[ "${QUIET:-0}" -eq 1 ]] && return 0
    [[ "${VERBOSE:-0}" -ge "$level" ]] || return 0
    _log_emit "$level" "$*"
}

vlog() {
    log 1 "$@"
}

vlog2() {
    log 2 "$@"
}

vlog3() {
    log 3 "$@"
}

vlog4() {
    log 4 "$@"
}

die() {
    _log_emit err "$*"
    exit 1
}

warn() {
    [[ "${QUIET:-0}" -eq 1 ]] && return 0
    _log_emit warn "$*"
}

require_commands() {
    local missing=()
    local cmd
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    if ((${#missing[@]} > 0)); then
        die "$(printf "$(_ 'missing required commands: %s')" "${missing[*]}")"
    fi
}

path_is_writable() {
    local path="$1"
    local dir

    if [[ -e "$path" ]]; then
        [[ -w "$path" ]]
        return
    fi

    dir="$(dirname "$path")"
    while [[ ! -d "$dir" && "$dir" != "/" ]]; do
        dir="$(dirname "$dir")"
    done
    [[ -d "$dir" && -w "$dir" ]]
}

# Run a command with elevation only when needed for the given path.
elevated() {
    local path="$1"
    shift

    if [[ "$(id -u)" -eq 0 ]]; then
        vlog2 "running as root: $*"
        "$@"
    elif path_is_writable "$path"; then
        vlog2 "writable $path, running without elevation: $*"
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        vlog2 "using sudo for $path: $*"
        sudo "$@"
    else
        die "$(printf "$(_ 'root privileges required to write %s (run as root or install sudo)')" "$path")"
    fi
}

# Run a command as root when the current user cannot.
run_as_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        vlog2 "running as root: $*"
        "$@"
    elif "$@"; then
        vlog3 "succeeded without elevation: $*"
    elif command -v sudo >/dev/null 2>&1; then
        vlog2 "using sudo: $*"
        sudo "$@"
    else
        die "$(_ 'root privileges required (run as root or install sudo)')"
    fi
}

install_as_root() {
    local src="$1"
    local dest="$2"
    elevated "$dest" mkdir -p "$(dirname "$dest")"
    elevated "$dest" cp "$src" "$dest"
}

remove_privileged() {
    local path="$1"
    [[ -e "$path" ]] || return 0
    elevated "$path" rm -f "$path"
}

init_lrm() {
    if [[ -n "${LRM_STATE_DIR:-}" ]]; then
        :
    elif [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
        LRM_STATE_DIR="$XDG_CONFIG_HOME/repoman/lrm"
    else
        LRM_STATE_DIR="$HOME/.config/repoman/lrm"
    fi
    mkdir -p "$LRM_STATE_DIR"
    vlog2 "state directory: $LRM_STATE_DIR"
}

_lrm_migrate_legacy_state() {
    local distro="$1"
    local legacy_mirror="$LRM_STATE_DIR/mirrors"
    local legacy_default="$LRM_STATE_DIR/default"
    local legacy_health="$LRM_STATE_DIR/health"

    [[ -f "$legacy_mirror" && ! -f "$LRM_MIRROR_FILE" ]] && cp -a "$legacy_mirror" "$LRM_MIRROR_FILE"
    [[ -f "$legacy_default" && ! -f "$LRM_DEFAULT_FILE" ]] && cp -a "$legacy_default" "$LRM_DEFAULT_FILE"
    [[ -f "$legacy_health" && ! -f "$LRM_HEALTH_FILE" ]] && cp -a "$legacy_health" "$LRM_HEALTH_FILE"
    if [[ -f "$legacy_mirror" ]]; then
        vlog2 "migrated legacy state into $LRM_STATE_DIR/$distro/"
    fi
}

lrm_set_distro_state() {
    local distro="${LRM_DISTRO:?}"

    [[ -n "${LRM_STATE_DIR:-}" ]] || die "$(_ 'internal error: call init_lrm before load_distro_backend')"

    LRM_MIRROR_FILE="$LRM_STATE_DIR/$distro/mirrors"
    LRM_DEFAULT_FILE="$LRM_STATE_DIR/$distro/default"
    LRM_HEALTH_FILE="$LRM_STATE_DIR/$distro/health"
    mkdir -p "$LRM_STATE_DIR/$distro"
    _lrm_migrate_legacy_state "$distro"
    invalidate_mirrors_cache
    unset LRM_HEALTH_LOADED
    vlog2 "distro state: $LRM_STATE_DIR/$distro/"
}

_lrm_ensure_distro_paths() {
    if [[ -n "${LRM_MIRROR_FILE:-}" ]]; then
        return 0
    fi
    [[ -n "${LRM_DISTRO:-}" && -n "${LRM_STATE_DIR:-}" ]] || \
        die "$(_ 'internal error: call init_lrm and load_distro_backend before mirror commands')"
    lrm_set_distro_state
}

health_load() {
    if [[ -z "${LRM_HEALTH_LOADED:-}" ]]; then
        declare -gA LRM_HEALTH=()
        LRM_HEALTH_LOADED=1
    fi
    if [[ -f "$LRM_HEALTH_FILE" ]]; then
        local alias status
        while IFS=$'\t' read -r alias status || [[ -n "$alias" ]]; do
            [[ -n "$alias" && -n "$status" ]] || continue
            LRM_HEALTH[$alias]="$status"
        done <"$LRM_HEALTH_FILE"
    fi
}

health_save() {
    local alias
    _lrm_ensure_distro_paths
    : >"$LRM_HEALTH_FILE"
    for alias in "${!LRM_HEALTH[@]}"; do
        printf '%s\t%s\n' "$alias" "${LRM_HEALTH[$alias]}" >>"$LRM_HEALTH_FILE"
    done
}

health_set() {
    local alias="$1"
    local status="$2"
    health_load
    LRM_HEALTH[$alias]="$status"
    health_save
}

health_get() {
    local alias="$1"
    health_load
    printf '%s\n' "${LRM_HEALTH[$alias]:-}"
}

health_apply_ping_results() {
    local line latency loss alias url
    health_load
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -n "$line" ]] || continue
        read -r latency loss alias url <<<"$line"
        if [[ "$latency" == "9999" || "$loss" -ge 100 ]]; then
            LRM_HEALTH[$alias]=bad
        else
            LRM_HEALTH[$alias]=ok
        fi
    done
    health_save
}

health_apply_bw_results() {
    local line score bps offset slope alias url
    health_load
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -n "$line" ]] || continue
        read -r score bps offset slope alias url <<<"$line"
        if [[ "$score" == "0" ]]; then
            LRM_HEALTH[$alias]=bad
        else
            LRM_HEALTH[$alias]=ok
        fi
    done
    health_save
}

build_mirror_list_order() {
    local i
    MIRROR_LIST_ORDER=()
    for i in "${!MIRROR_ALIASES[@]}"; do
        MIRROR_LIST_ORDER+=("$i")
    done

    local a b pa pb
    local j k tmp
    for ((j = 0; j < ${#MIRROR_LIST_ORDER[@]}; j++)); do
        for ((k = j + 1; k < ${#MIRROR_LIST_ORDER[@]}; k++)); do
            a="${MIRROR_LIST_ORDER[$j]}"
            b="${MIRROR_LIST_ORDER[$k]}"
            pa="${MIRROR_PRIORITIES[$a]}"
            pb="${MIRROR_PRIORITIES[$b]}"
            if ((pb < pa)) || { ((pb == pa)) && [[ "${MIRROR_ALIASES[$b]}" < "${MIRROR_ALIASES[$a]}" ]]; }; then
                tmp="${MIRROR_LIST_ORDER[$j]}"
                MIRROR_LIST_ORDER[$j]="${MIRROR_LIST_ORDER[$k]}"
                MIRROR_LIST_ORDER[$k]="$tmp"
            fi
        done
    done
}

mirror_list_mark() {
    local alias="$1"
    local default=""

    if [[ -f "$LRM_DEFAULT_FILE" ]]; then
        default="$(tr -d '[:space:]' <"$LRM_DEFAULT_FILE")"
    fi
    if [[ "$alias" == "$default" ]]; then
        printf '%s' '* '
        return 0
    fi
    case "$(health_get "$alias")" in
    bad) printf '%s' '- ' ;;
    ok) printf '%s' '  ' ;;
    *) printf '%s' '? ' ;;
    esac
}

mirror_resolve_alias() {
    local target="$1"
    local n max

    if mirror_index "$target" >/dev/null 2>&1; then
        printf '%s\n' "$target"
        return 0
    fi

    if [[ "$target" =~ ^[0-9]+$ ]]; then
        build_mirror_list_order
        max="${#MIRROR_LIST_ORDER[@]}"
        n="$target"
        if ((max == 0 || n < 1 || n > max)); then
        die "$(printf "$(_ 'mirror number out of range: %s (1-%s)')" "$target" "${max:-0}")"
        fi
        printf '%s\n' "${MIRROR_ALIASES[${MIRROR_LIST_ORDER[$((n - 1))]}]}"
        return 0
    fi

    die "$(printf "$(_ 'mirror not found: %s')" "$target")"
}

validate_alias() {
    local alias="$1"
    if [[ ! "$alias" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
        die "$(printf "$(_ 'invalid alias: %s')" "$alias")"
    fi
}

validate_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https?:// ]]; then
        die "$(printf "$(_ 'invalid mirror URL (must start with http:// or https://): %s')" "$url")"
    fi
}

url_host() {
    local url="$1"
    printf '%s\n' "$url" | sed -E 's#^[a-zA-Z]+://([^/]+)/?.*#\1#'
}

mirror_index() {
    local alias="$1"
    local i
    for i in "${!MIRROR_ALIASES[@]}"; do
        if [[ "${MIRROR_ALIASES[$i]}" == "$alias" ]]; then
            printf '%s\n' "$i"
            return 0
        fi
    done
    return 1
}

mirror_add() {
    local alias="$1"
    local priority="$2"
    local url="$3"
    local idx

    if idx="$(mirror_index "$alias" 2>/dev/null)"; then
        MIRROR_PRIORITIES[$idx]="$priority"
        MIRROR_URLS[$idx]="$url"
    else
        MIRROR_ALIASES+=("$alias")
        MIRROR_PRIORITIES+=("$priority")
        MIRROR_URLS+=("$url")
    fi
}

mirror_remove() {
    local alias="$1"
    local idx
    idx="$(mirror_index "$alias")" || die "$(printf "$(_ 'mirror not found: %s')" "$alias")"

    local new_aliases=()
    local new_priorities=()
    local new_urls=()
    local i
    for i in "${!MIRROR_ALIASES[@]}"; do
        [[ "$i" == "$idx" ]] && continue
        new_aliases+=("${MIRROR_ALIASES[$i]}")
        new_priorities+=("${MIRROR_PRIORITIES[$i]}")
        new_urls+=("${MIRROR_URLS[$i]}")
    done
    MIRROR_ALIASES=("${new_aliases[@]}")
    MIRROR_PRIORITIES=("${new_priorities[@]}")
    MIRROR_URLS=("${new_urls[@]}")

    if [[ -f "$LRM_DEFAULT_FILE" ]] && [[ "$(cat "$LRM_DEFAULT_FILE")" == "$alias" ]]; then
        rm -f "$LRM_DEFAULT_FILE"
    fi

    health_load
    unset 'LRM_HEALTH[$alias]'
    health_save
}

load_mirrors() {
    if [[ "${LRM_MIRRORS_LOADED:-0}" -eq 1 ]]; then
        return 0
    fi

    _lrm_ensure_distro_paths

    MIRROR_ALIASES=()
    MIRROR_PRIORITIES=()
    MIRROR_URLS=()
    [[ -f "$LRM_MIRROR_FILE" ]] || return 0

    local line alias priority url
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        read -r alias priority url <<<"$line"
        [[ -n "$alias" && -n "$priority" && -n "$url" ]] || continue
        mirror_add "$alias" "$priority" "$url"
    done <"$LRM_MIRROR_FILE"
    LRM_MIRRORS_LOADED=1
    vlog2 "loaded ${#MIRROR_ALIASES[@]} mirrors from $LRM_MIRROR_FILE"
}

invalidate_mirrors_cache() {
    LRM_MIRRORS_LOADED=0
}

save_mirrors() {
    local i
    _lrm_ensure_distro_paths
    mkdir -p "$(dirname "$LRM_MIRROR_FILE")"
    : >"$LRM_MIRROR_FILE"
    for i in "${!MIRROR_ALIASES[@]}"; do
        printf '%s\t%s\t%s\n' \
            "${MIRROR_ALIASES[$i]}" "${MIRROR_PRIORITIES[$i]}" "${MIRROR_URLS[$i]}" \
            >>"$LRM_MIRROR_FILE"
    done
    LRM_MIRRORS_LOADED=1
}

list_mirrors_sorted() {
    local num idx alias mark
    build_mirror_list_order
    health_load

    num=0
    for idx in "${MIRROR_LIST_ORDER[@]}"; do
        num=$((num + 1))
        alias="${MIRROR_ALIASES[$idx]}"
        mark="$(mirror_list_mark "$alias")"
        if [[ "${LRM_LIST_PRIORITY:-0}" -eq 1 ]]; then
            printf '%s[%d] %s %s %s\n' \
                "$mark" "$num" "$alias" "${MIRROR_PRIORITIES[$idx]}" "${MIRROR_URLS[$idx]}"
        else
            printf '%s[%d] %s\n' "$mark" "$num" "$alias"
        fi
    done
}

mirror_get_url() {
    local alias="$1"
    local idx
    idx="$(mirror_index "$alias")" || die "$(printf "$(_ 'mirror not found: %s')" "$alias")"
    printf '%s\n' "${MIRROR_URLS[$idx]}"
}

mirror_use() {
    local target="$1"
    local alias url
    alias="$(mirror_resolve_alias "$target")"
    url="$(mirror_get_url "$alias")"
    printf '%s\n' "$alias" >"$LRM_DEFAULT_FILE"
    apply_mirror "$url"
    log "$(printf "$(_ 'using mirror %s (%s)')" "$alias" "$url")"
}

_ping_mirror_worker() {
    local idx="$1"
    local alias="$2"
    local url="$3"
    local outdir="$4"
    local host latency loss line

    host="$(url_host "$url")"
    vlog "pinging $alias ($host)"
    if ! mapfile -t ping_lines < <(ping -c "${LRM_PING_COUNT:-3}" -W "${LRM_PING_TIMEOUT:-2}" "$host" 2>/dev/null | tail -2); then
        vlog3 "ping $alias ($host): unreachable"
        printf '%s\n' "9999 100 $alias $url" >"$outdir/$idx"
        return 0
    fi
    if ((${#ping_lines[@]} < 2)); then
        vlog3 "ping $alias ($host): incomplete response"
        printf '%s\n' "9999 100 $alias $url" >"$outdir/$idx"
        return 0
    fi

    local loss_line="${ping_lines[0]}"
    local rtt_line="${ping_lines[1]}"
    if [[ "$rtt_line" =~ rtt\ min/avg/max/mdev\ =\ [0-9.]+/([0-9.]+)/ ]]; then
        latency="${BASH_REMATCH[1]}"
    elif [[ "$rtt_line" =~ round-trip\ min/avg/max/stddev\ =\ [0-9.]+/([0-9.]+)/ ]]; then
        latency="${BASH_REMATCH[1]}"
    else
        latency="9999"
    fi
    if [[ "$loss_line" =~ ([0-9]+)%\ packet\ loss ]]; then
        loss="${BASH_REMATCH[1]}"
    else
        loss="100"
    fi
    printf '%s\n' "$latency $loss $alias $url" >"$outdir/$idx"
    vlog3 "ping $alias ($host): latency=${latency}ms loss=${loss}%"
}

format_num_commas() {
    awk -v n="$1" 'BEGIN {
        n = int(n + 0.5)
        sign = (n < 0 ? "-" : "")
        if (n < 0) {
            n = -n
        }
        if (n < 1000) {
            printf "%s%d\n", sign, n
            exit
        }
        s = ""
        while (n >= 1000) {
            s = sprintf(",%03d%s", n % 1000, s)
            n = int(n / 1000)
        }
        printf "%s%d%s\n", sign, n, s
    }'
}

format_bps() {
    awk -v bps="$1" 'BEGIN {
        if (bps + 0 <= 0) {
            print "0Bps"
            exit
        }
        split("Bps kBps MBps GBps TBps", units, " ")
        v = bps + 0
        u = 1
        while (v >= 1000 && u < 5) {
            v /= 1000
            u++
        }
        if (v == int(v + 0)) {
            printf "%d%s\n", int(v + 0), units[u]
        } else if (v >= 10) {
            printf "%.1f%s\n", v, units[u]
        } else {
            printf "%.2f%s\n", v, units[u]
        }
    }'
}

_bw_score_from_output() {
    awk -v alias="$1" -v url="$2" -v ref="${LRM_BWTEST_REF_BYTES:-3000000}" '
    function is_count_line(line,    f) {
        return (split(line, f, " ") == 4 && f[2] + 0 > 0 && f[4] + 0 > 0)
    }
    {
        lines[++n] = $0
    }
    END {
        score = 0
        bps = 0
        offset = 0
        slope = 0
        intercept = 0
        count_line = ""
        poly_line = ""

        if (n >= 2 && is_count_line(lines[n - 1])) {
            count_line = lines[n - 1]
            poly_line = lines[n]
        } else if (n >= 1 && is_count_line(lines[n])) {
            count_line = lines[n]
        }

        if (count_line == "") {
            printf "0 0 0 0 %s %s\n", alias, url
            exit
        }

        split(count_line, c, " ")
        size = c[2] + 0
        bps = c[4] + 0
        if (size <= 0 || bps <= 0) {
            printf "0 0 0 0 %s %s\n", alias, url
            exit
        }

        # Effective throughput for a ref-sized file (default 3 MiB):
        #   time = offset + ref/bps  =>  score = ref / time = ref*bps / (offset*bps + ref)
        # Slow offset hurts more when bps is high (short transfer); less when bps is low.
        score = ref * bps / (offset * bps + ref)

        if (poly_line != "") {
            pn = split(poly_line, p, " ")
            if (pn >= 1) {
                offset = p[1] + 0
                score = ref * bps / (offset * bps + ref)
            }
            if (pn >= 2) {
                slope = p[2] + 0
            }
            if (pn >= 3) {
                intercept = p[3] + 0
            }
            if (intercept > 0 && slope != 0) {
                t_data = ref / bps
                end_ratio = (intercept + slope * t_data) / intercept
                if (end_ratio < 1) {
                    score *= (end_ratio > 0.5 ? end_ratio : 0.5)
                }
            }
        }

        if (score < 0) {
            score = 0
        }
        printf "%.0f %.0f %.6g %.6g %s %s\n", score, bps, offset, slope, alias, url
    }'
}

_bw_mirror_worker() {
    local idx="$1"
    local alias="$2"
    local url="$3"
    local outdir="$4"
    local test_url getbar_out score_line

    test_url="$(mirror_probe_url "$url")"
    vlog "bandwidth test $alias ($test_url)"
    vlog3 "getbar $LRM_GETBAR $LRM_GETBAR_OPTS $test_url"

    getbar_out="$(mktemp "${TMPDIR:-/tmp}/lrm-getbar.XXXXXX")"
    if ! $LRM_GETBAR $LRM_GETBAR_OPTS "$test_url" >"$getbar_out" 2>/dev/null; then
        vlog3 "getbar failed for $alias"
    fi

    if [[ "${VERBOSE:-0}" -ge 4 && -s "$getbar_out" ]]; then
        vlog4 "getbar output for $alias:"
        while IFS= read -r line || [[ -n "$line" ]]; do
            vlog4 "  $line"
        done <"$getbar_out"
    fi

    score_line="$(_bw_score_from_output "$alias" "$url" <"$getbar_out")"
    vlog3 "bw $alias: $score_line"
    rm -f "$getbar_out"
    printf '%s\n' "$score_line" >"$outdir/$idx"
}

run_pingtest() {
    require_commands ping awk sort
    ((${#MIRROR_ALIASES[@]} > 0)) || die "$(_ 'no mirrors configured')"

    vlog2 "ping testing ${#MIRROR_ALIASES[@]} mirrors in parallel"
    local tmpdir i
    local -a results=()
    tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/lrm-ping.XXXXXX")"

    for i in "${!MIRROR_ALIASES[@]}"; do
        _ping_mirror_worker "$i" "${MIRROR_ALIASES[$i]}" "${MIRROR_URLS[$i]}" "$tmpdir" &
    done
    wait

    for i in "${!MIRROR_ALIASES[@]}"; do
        if [[ -f "$tmpdir/$i" ]]; then
            results+=("$(<"$tmpdir/$i")")
        else
            results+=("9999 100 ${MIRROR_ALIASES[$i]} ${MIRROR_URLS[$i]}")
        fi
    done
    rm -rf "$tmpdir"

    health_apply_ping_results <<<"$(printf '%s\n' "${results[@]}")"

    printf '%s\n' "${results[@]}" | sort -n -k1,1n -k2,2n | while read -r latency loss alias url; do
        printf '%s %s latency=%sms loss=%s%%\n' "$alias" "$url" "$latency" "$loss"
    done
}

run_bwtest() {
    require_commands "$LRM_GETBAR" awk sort
    ((${#MIRROR_ALIASES[@]} > 0)) || die "$(_ 'no mirrors configured')"

    vlog2 "bandwidth testing ${#MIRROR_ALIASES[@]} mirrors in parallel (ref=${LRM_BWTEST_REF_BYTES} bytes)"
    local tmpdir i
    local -a results=()
    tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/lrm-bw.XXXXXX")"

    for i in "${!MIRROR_ALIASES[@]}"; do
        _bw_mirror_worker "$i" "${MIRROR_ALIASES[$i]}" "${MIRROR_URLS[$i]}" "$tmpdir" &
    done
    wait

    for i in "${!MIRROR_ALIASES[@]}"; do
        if [[ -f "$tmpdir/$i" ]]; then
            results+=("$(<"$tmpdir/$i")")
        else
            results+=("0 0 0 0 ${MIRROR_ALIASES[$i]} ${MIRROR_URLS[$i]}")
        fi
    done
    rm -rf "$tmpdir"

    health_apply_bw_results <<<"$(printf '%s\n' "${results[@]}")"

    printf '%s\n' "${results[@]}" | sort -t' ' -k1,1nr | while read -r score bps offset slope alias url; do
        printf '%s %s score=%s bps=%s offset=%ss slope=%s\n' \
            "$alias" "$url" \
            "$(format_num_commas "$score")" \
            "$(format_bps "$bps")" \
            "$offset" "$slope"
    done
}

pick_best_bwtest() {
    local best
    best="$(run_bwtest | awk 'NR==1 {print $1}')"
    [[ -n "$best" && "$best" != "0" ]] || return 1
    printf '%s\n' "$best"
}
