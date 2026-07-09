# this file is symlinked to/from .bashrc and .zshrc
# all content must be viable for both shells

export SHELL_NAME=${SHELL##*/}
export XDG_CONFIG_HOME="$HOME/.config"

# bash-completion
[[ "$SHELL_NAME" == "bash" ]] && source /usr/share/bash-completion/bash_completion

if [[ $OSTYPE == 'linux' ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/share/pkgconfig:${PKG_CONFIG_PATH}"
else
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# cargo
export PATH="$HOME/.cargo/bin:$PATH"

# dprint
export DPRINT_INSTALL="$HOME/.dprint"
export PATH="$DPRINT_INSTALL/bin:$PATH"

# rancher desktop
export PATH="$HOME/.rd/bin:$PATH"
if [[ $OSTYPE != 'linux' ]]; then
  export DOCKER_HOST=unix://$HOME/.rd/docker.sock
fi

export EDITOR='hx'
export VISUAL='hx'
export LESS='-FIMRX'
export OPENCODE_DISABLE_TERMINAL_TITLE=1

alias ?='echo $?'
alias k='kubectl'
alias kc='kubectx'
alias lg='lazygit'
alias ll='ls -alh'
alias llr='ls -alhrt'
alias oc='opencode'
alias y='cd $(yazi --cwd-file=/dev/stdout 2> /dev/null)'

# completions
eval "$(k3d completion $SHELL_NAME)"
eval "$(task --completion $SHELL_NAME)"

# override with local settings
# this must be at the end of the file
if [[ -x "$HOME/.${SHELL_NAME}rc.local" ]]; then
  source "$HOME/.${SHELL_NAME}rc.local"
fi
