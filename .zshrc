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

# rancher desktop
export PATH="$HOME/.rd/bin:$PATH"

alias lg='lazygit'
alias k="kubectl"

# override with local settings
# this must be at the end of the file
if [[ -x "$HOME/.$(basename $0)rc.local" ]]; then
  source "$HOME/.$(basename $0)rc.local"
fi
