function fish_greeting
    # if the terminal emulator is not ghostty we use a specific fastfetch config
    if test "$TERM_PROGRAM" = "ghostty"
        fastfetch -c ~/.config/fastfetch/config.jsonc
    else
        fastfetch -c ~/.config/fastfetch/vscode.jsonc
    end
end