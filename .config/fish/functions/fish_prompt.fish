function fish_prompt
        if not set -q VIRTUAL_ENV_DISABLE_PROMPT
                set -g VIRTUAL_ENV_DISABLE_PROMPT true
        end
        set_color DC143C
        printf '%s' $USER
        set_color 696969
        printf ' at '

        set_color 696969
        echo -n (prompt_hostname)
        set_color 696969
        printf ' in '

        set_color C0C0C0
        printf '%s' (prompt_pwd)
        set_color normal

        # Line 2
        echo
        if test -n "$VIRTUAL_ENV"
                printf "(%s) " (set_color FF4500)(path basename $VIRTUAL_ENV)(set_color normal)
        end
        set_color DC143C
        printf '↪ '
        set_color normal
end
