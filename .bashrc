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
if [[ $OSTYPE != 'linux' ]]; then
  export DOCKER_HOST=unix://$HOME/.rd/docker.sock
fi

export EDITOR='hx'
export VISUAL='hx'
export LESS='-FIMRX'

alias k='kubectl'
alias kc='kubectx'
alias lg='lazygit'
alias ll='ls -la'
alias y='cd $(yazi --cwd-file=/dev/stdout 2> /dev/null)'

# completions
source <(k3d completion bash)

# override with local settings
# this must be at the end of the file
if [[ -x "$HOME/.$(basename $SHELL)rc.local" ]]; then
  source "$HOME/.$(basename $SHELL)rc.local"
fi
