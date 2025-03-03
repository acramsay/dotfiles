if [[ ${TERM_PROGRAM} != "vscode" ]]; then
  eval "$(zellij setup --generate-auto-start zsh)"
fi

alias k="kubectl"

export PATH="$HOME/.rd/bin:$PATH"
