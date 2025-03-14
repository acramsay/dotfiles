# this file is symlinked to/from .bashrc and .zshrc
# all content must be viable for both shells

# homebrew
if [[ $OSTYPE == "linux" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# zellij
if [[ ${TERM_PROGRAM} != "vscode" ]]; then
  eval "$(zellij setup --generate-auto-start $(basename $SHELL))"
fi

# dprint
export DPRINT_INSTALL="/home/alex/.dprint"
export PATH="$DPRINT_INSTALL/bin:$PATH"

# rancher desktop
export PATH="$HOME/.rd/bin:$PATH"

alias lg='lazygit'
alias ll='ls -la'
alias k="kubectl"

# override with local settings
# this must be at the end of the file
if [[ -x "~/$(basename $0).local" ]]; then
  source "~/$(basename $0).local"
fi
