tap "wezterm/wezterm-linuxbrew" if OS.linux?
brew "wezterm"
cask "font-comic-mono"
cask "font-comic-neue"
cask "font-comic-relief"
cask "font-comic-shanns-mono-nerd-font"

brew "zellij"
brew "ranger"

brew "helix"
brew "yaml-language-server"
brew "yamlfmt"
brew "go"
brew "delve"
brew "gofumpt"
brew "gopls"
brew "dprint"
brew "marksman"
brew "rust"
brew "rustup"

# dev tools
brew "git"
brew "go-task"
brew "lazygit"
brew "ollama"
brew "pre-commit"

# terraform
tap "hashicorp/tap"
brew "hashicorp/tap/terraform"
brew "terragrunt"

# k8s tools
cask "rancher" # not available on linux
brew "kustomize"
brew "k3d"
brew "k9s"
brew "tilt"

# if OS.linux?
  # cask "discord" # not available on linux
  # cask "librewolf" # not available on linux
  # cask "steam" # not available on linux
# end

if OS.mac?
  cask "slack"
  tap "satrik/togglemute", "https://github.com/satrik/homebrew-togglemute.git"
  cask "togglemute", args: { no_quarantine: true }
  cask "meetingbar"
  cask "finicky"
end
