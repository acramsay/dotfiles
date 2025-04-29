# this file is symlinked to/from .bashrc and .zshrc
# all content must be viable for both shells

# homebrew
if [[ $OSTYPE == 'linux' ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# cargo
export PATH="$HOME/.cargo/bin:$PATH"

# dprint
export DPRINT_INSTALL="/home/alex/.dprint"
export PATH="$DPRINT_INSTALL/bin:$PATH"

# rancher desktop
export PATH="$HOME/.rd/bin:$PATH"

export EDITOR='hx'
export VISUAL='hx'

alias lg='lazygit'
alias ll='ls -la'
alias k='kubectl'
alias kc='kubectx'

# override with local settings
# this must be at the end of the file
if [[ -x "$HOME/.$(basename $SHELL)rc.local" ]]; then
  source "$HOME/.$(basename $SHELL)rc.local"
fi
