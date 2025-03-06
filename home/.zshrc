# used in macos

eval "$(/opt/homebrew/bin/brew shellenv)"
source ~/.bashrc

if [[ -r ~/.bashrc.local ]]; then
    . ~/.bashrc.local
fi
