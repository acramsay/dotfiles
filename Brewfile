if OS.linux?
  tap "wezterm/wezterm-linuxbrew"
  brew "wezterm", args: ["HEAD"]
  brew "docker"
  brew "kubectl"
  brew "kubernetes-cli"
  brew "git-credential-libsecret"
end

if OS.mac?
  cask "wezterm@nightly"
  cask "slack"
  tap "satrik/togglemute", "https://github.com/satrik/homebrew-togglemute.git"
  cask "togglemute", args: { no_quarantine: true }
  cask "meetingbar"
  cask "finicky"
  cask "rancher"
end

cask "font-recursive-code"

brew "yazi"

# brew "helix", args: ["HEAD"]
tap "sst/tap"
brew "sst/tap/opencode"
brew "yaml-language-server"
brew "yamlfmt"
brew "go"
brew "golangci-lint"
brew "golangci-lint-langserver"
brew "delve"
brew "gofumpt"
brew "gopls"
brew "dprint"
brew "lua-language-server"
brew "marksman"
brew "rust"
brew "rustup"
brew "typescript-language-server"

# dev tools
brew "git"
brew "go-task"
brew "httpie"
brew "lazygit"
brew "pre-commit"
brew "syncthing"

# terraform
tap "hashicorp/tap"
brew "hashicorp/tap/terraform"
brew "terragrunt"

# k8s tools
brew "fzf"
brew "k3d"
brew "k9s"
brew "kubeconform"
brew "kubectx"
brew "kustomize"
brew "tilt"

