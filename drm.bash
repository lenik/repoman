# bash completion for drm

_drm_global_opts='-v -vv -vvv -vvvv -q --verbose --quiet -h --help --version'
_drm_commands='list add remove use pingtest bwtest pingsel bwsel help version'

_drm_apply_opts='-c --config-only --help'

_drm_cmd_word()
{
    local i
    for ((i = 1; i < cword; i++)); do
        case "${words[i]}" in
        -*) ;;
        list|add|remove|use|pingtest|bwtest|pingsel|bwsel|help|version)
            printf '%s\n' "${words[i]}"
            return 0
            ;;
        esac
    done
    return 1
}

_drm_mirror_candidates()
{
    mapfile -t line < <(drm list 2>/dev/null)
    printf '%s\n' "${line[@]}"
}

_drm()
{
    local cur prev words cword cmd
    _init_completion || return

    cur="${cur:-}"
    prev="${prev:-}"

    case "$prev" in
    -p|--priority) return ;;
    esac

    cmd="$(_drm_cmd_word 2>/dev/null || true)"

    if [[ -z "$cmd" ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "$_drm_global_opts $_drm_commands" -- "$cur"))
        else
            COMPREPLY=($(compgen -W "$_drm_commands" -- "$cur"))
        fi
        return
    fi

    case "$cmd" in
    list)
        [[ "$cur" == -* ]] && COMPREPLY=($(compgen -W '-c --char -p --priority --help' -- "$cur"))
        ;;
    add)
        [[ "$cur" == -* ]] && COMPREPLY=($(compgen -W '-p --priority --help -10 -20 -50 -100' -- "$cur"))
        ;;
    remove|use|pingsel|bwsel)
        if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "$_drm_apply_opts" -- "$cur"))
        elif [[ "$cmd" == remove || "$cmd" == use ]]; then
            case "$prev" in
            -n|--count|-W|--timeout|--ref|-p|--priority) ;;
            *)
                local mirrors nums line
                while IFS= read -r line; do
                    [[ -n "$line" ]] || continue
                    mirrors+=" $(awk '{print $NF}' <<<"$line")"
                    nums+=" $(sed -n 's/.*\[\([0-9][0-9]*\)\].*/\1/p' <<<"$line")"
                done < <(_drm_mirror_candidates)
                COMPREPLY=($(compgen -W "${mirrors# } ${nums# }" -- "$cur"))
                ;;
            esac
        fi
        ;;
    pingtest|pingsel)
        [[ "$cur" == -* ]] && COMPREPLY=($(compgen -W '-n --count -W --timeout -c --config-only --help' -- "$cur"))
        ;;
    bwtest|bwsel)
        [[ "$cur" == -* ]] && COMPREPLY=($(compgen -W "--ref -c --config-only --help $_drm_apply_opts" -- "$cur"))
        ;;
    esac
}

complete -F _drm drm
