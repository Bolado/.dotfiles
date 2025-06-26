# source other .fish files
source ~/.config/fish/aliases.fish

eval "$(/opt/homebrew/bin/brew shellenv)"

# create .hushlogin file if it doesn't exist to remove login message next time
if not test -f ~/.hushlogin
    touch ~/.hushlogin
end