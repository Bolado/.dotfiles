# Navigation
function ..    ; cd .. ; end
function ...   ; cd ../.. ; end
function ....  ; cd ../../.. ; end
function ..... ; cd ../../../.. ; end

# Files and folders
alias hosts='sudo nano /etc/hosts'
alias dotfiles="code-insiders ~/.dotfiles"
alias projects="cd ~/Projects"

# Commands
alias ai-ui="DATA_DIR=~/.open-webui uvx --python 3.11 open-webui@latest serve"
alias ai-api="swama serve --host 0.0.0.0 --port 28100"
