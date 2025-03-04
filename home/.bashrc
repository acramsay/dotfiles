if [[ ${TERM_PROGRAM} != "vscode" ]]; then
  eval "$(zellij setup --generate-auto-start $(basename $SHELL))"
fi

export DPRINT_INSTALL="/home/alex/.dprint"                                                                                                 
export PATH="$DPRINT_INSTALL/bin:$PATH"
export PATH="$HOME/.rd/bin:$PATH"

alias lg='lazygit'
alias k="kubectl"
