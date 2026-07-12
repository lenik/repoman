# bash completion for lrm

_lrm_global_opts='-v -vv -vvv -vvvv -q --verbose --quiet -h --help -o --distro -l --list-distros --version'
_lrm_commands='list add remove use pingtest bwtest pingsel bwsel help version'

_lrm_debian_apply_opts='-c --config-only -a --all --minimal -s --src --no-src -u --updates --no-updates -b --backports --no-backports --security --no-security --contrib --non-free --firmware --suite'
_lrm_rpm_apply_opts='-c --config-only -a --all -e --everything -E --epel --minimal --baseos --no-baseos --appstream --no-appstream --crb --powertools --no-crb --no-epel -r --releasever --arch'
_lrm_apply_opts="$_lrm_debian_apply_opts $_lrm_rpm_apply_opts --help"

_lrm_distro_args()
{
    local i args=()
    for ((i = 1; i < cword; i++)); do
        case "${words[i]}" in
        -o|--distro)
            if (( i + 1 < cword )); then
                args+=(-o "${words[i + 1]}")
            fi
            ((i++))
            ;;
        esac
    done
    printf '%s\n' "${args[@]}"
}

_lrm_cmd_word()
{
    local i
    for ((i = 1; i < cword; i++)); do
        case "${words[i]}" in
        -o|--distro)
            ((i++))
            ;;
        -*) ;;
        list|add|remove|use|pingtest|bwtest|pingsel|bwsel|help|version)
            printf '%s\n' "${words[i]}"
            return 0
            ;;
        esac
    done
    return 1
}

_lrm_cmd_idx()
{
    local i
    for ((i = 1; i < cword; i++)); do
        case "${words[i]}" in
        -o|--distro)
            ((i++))
            ;;
        -*) ;;
        list|add|remove|use|pingtest|bwtest|pingsel|bwsel|help|version)
            printf '%s\n' "$i"
            return 0
            ;;
        esac
    done
    return 1
}

_lrm_mirror_candidates()
{
    local -a distro_args=()
    local line
    mapfile -t distro_args < <(_lrm_distro_args)
    mapfile -t line < <(lrm "${distro_args[@]}" list 2>/dev/null)
    printf '%s\n' "${line[@]}"
}

_lrm()
{
    local cur prev words cword cmd cmd_idx
    _init_completion || return

    cur="${cur:-}"
    prev="${prev:-}"

    case "$prev" in
    -o|--distro)
        local distros
        distros="$(lrm --list-distros 2>/dev/null)"
        COMPREPLY=($(compgen -W "$distros" -- "$cur"))
        return
        ;;
    -p|--priority)
        return
        ;;
    esac

    cmd="$(_lrm_cmd_word 2>/dev/null || true)"
    cmd_idx="$(_lrm_cmd_idx 2>/dev/null || true)"

    if [[ -z "$cmd" ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "$_lrm_global_opts $_lrm_commands" -- "$cur"))
        else
            COMPREPLY=($(compgen -W "$_lrm_commands" -- "$cur"))
        fi
        return
    fi

    if [[ "$cur" == -* && -n "$cmd_idx" && "$cword" -le $((cmd_idx + 1)) ]]; then
        case "$cmd" in
        list)
            COMPREPLY=($(compgen -W '-p --priority --help' -- "$cur"))
            ;;
        add)
            COMPREPLY=($(compgen -W '-p --priority --help' -- "$cur"))
            COMPREPLY+=($(compgen -W '-10 -20 -50 -100' -- "$cur"))
            ;;
        remove|use)
            COMPREPLY=($(compgen -W "$_lrm_apply_opts" -- "$cur"))
            ;;
        pingtest)
            COMPREPLY=($(compgen -W '-n --count -W --timeout --help' -- "$cur"))
            ;;
        pingsel)
            COMPREPLY=($(compgen -W "-n --count -W --timeout $_lrm_apply_opts" -- "$cur"))
            ;;
        bwtest)
            COMPREPLY=($(compgen -W '--ref --help' -- "$cur"))
            ;;
        bwsel)
            COMPREPLY=($(compgen -W "--ref $_lrm_apply_opts" -- "$cur"))
            ;;
        help|version)
            COMPREPLY=($(compgen -W '--help' -- "$cur"))
            ;;
        esac
        return
    fi

    case "$cmd" in
    list|pingtest|bwtest)
        if [[ "$cur" == -* ]]; then
            case "$cmd" in
            list)
                COMPREPLY=($(compgen -W '-p --priority --help' -- "$cur"))
                ;;
            pingtest)
                COMPREPLY=($(compgen -W '-n --count -W --timeout --help' -- "$cur"))
                ;;
            bwtest)
                COMPREPLY=($(compgen -W '--ref --help' -- "$cur"))
                ;;
            esac
        fi
        ;;
    add)
        if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W '-p --priority --help' -- "$cur"))
            COMPREPLY+=($(compgen -W '-10 -20 -50 -100' -- "$cur"))
        fi
        ;;
    remove|use)
        if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "$_lrm_apply_opts" -- "$cur"))
        elif [[ "$cur" != -* ]]; then
            case "$prev" in
            -n|--count|-W|--timeout|--ref|-r|--releasever|--arch|--suite|-p|--priority|-o|--distro)
                ;;
            *)
                local mirrors nums line
                while IFS= read -r line; do
                    [[ -n "$line" ]] || continue
                    mirrors+=" $(awk '{print $NF}' <<<"$line")"
                    nums+=" $(sed -n 's/^[ *?-]*\[\([0-9]*\)\].*/\1/p' <<<"$line")"
                done < <(_lrm_mirror_candidates)
                COMPREPLY=($(compgen -W "${mirrors# } ${nums# }" -- "$cur"))
                ;;
            esac
        fi
        ;;
    pingsel|bwsel)
        if [[ "$cur" == -* ]]; then
            case "$cmd" in
            pingsel)
                COMPREPLY=($(compgen -W "-n --count -W --timeout $_lrm_apply_opts" -- "$cur"))
                ;;
            bwsel)
                COMPREPLY=($(compgen -W "--ref $_lrm_apply_opts" -- "$cur"))
                ;;
            esac
        fi
        ;;
    esac
}

complete -F _lrm lrm
