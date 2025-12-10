# source other .fish files
source ~/.config/fish/aliases.fish

eval "$(/opt/homebrew/bin/brew shellenv)"

# create .hushlogin file if it doesn't exist to remove login message next time
if not test -f ~/.hushlogin
    touch ~/.hushlogin
end

# setup bitwarden ssh agent
export SSH_AUTH_SOCK=/Users/bolado/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock
