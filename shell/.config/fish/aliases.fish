# Navigation
function ..    ; cd .. ; end
function ...   ; cd ../.. ; end
function ....  ; cd ../../.. ; end
function ..... ; cd ../../../.. ; end

# Files and folders
alias hosts='sudo nano /etc/hosts'
alias dotfiles="code-insiders ~/.dotfiles"
alias projects="cd ~/Projects"

# File search
alias ffind="find . -name"

# Commands
alias ai-ui="DATA_DIR=~/.open-webui uvx --python 3.11 open-webui@latest serve"
alias ai-serve="swama serve --host 0.0.0.0 --port 28100"

# just source fish config
alias source-fish="source ~/.config/fish/config.fish"

# Docker
alias dcu="docker compose up"

# Python
alias uvi="uv pip install"
alias uvu="uv pip uninstall"
alias uvr="uv pip install -r requirements.txt"
alias uve="uv venv"
alias uvfreeze="uv pip freeze > requirements.txt"