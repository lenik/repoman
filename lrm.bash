# bash completion for lrm

_lrm()
{
    local cur prev words cword
    _init_completion || return

    if [[ $cword -eq 1 && $cur == -* ]]; then
        COMPREPLY=($(compgen -W '--verbose --quiet --help --version' -- "$cur"))
        return
    fi

    local commands='list add remove use pingtest bwtest pingsel bwsel help version'
    if [[ $cword -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        return
    fi

    case "${words[1]}" in
        list)
            if [[ $cur == -* ]]; then
                COMPREPLY=($(compgen -W '-p --priority --help' -- "$cur"))
            fi
            ;;
        add)
            if [[ $cur == -* ]]; then
                COMPREPLY=($(compgen -W '-p --priority --help' -- "$cur"))
            fi
            ;;
        remove|use)
            if [[ $cur == -* ]]; then
                COMPREPLY=($(compgen -W '-c --config-only --help' -- "$cur"))
            elif [[ $cword -eq 2 ]]; then
                local mirrors nums
                mirrors="$(lrm list 2>/dev/null | awk '{print $NF}')"
                nums="$(lrm list 2>/dev/null | sed -n 's/^[ *?-]*\[\([0-9]*\)\].*/\1/p')"
                COMPREPLY=($(compgen -W "$mirrors $nums" -- "$cur"))
            fi
            ;;
        pingsel|bwsel)
            if [[ $cur == -* ]]; then
                COMPREPLY=($(compgen -W '-c --config-only --help' -- "$cur"))
            fi
            ;;
        pingtest|pingsel)
            if [[ $cur == -* ]]; then
                COMPREPLY=($(compgen -W '-n --count -W --timeout -c --config-only --help' -- "$cur"))
            fi
            ;;
        bwtest|bwsel)
            if [[ $cur == -* ]]; then
                COMPREPLY=($(compgen -W '--ref -c --config-only --help' -- "$cur"))
            fi
            ;;
    esac
}

complete -F _lrm lrm
