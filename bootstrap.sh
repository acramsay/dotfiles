# Install hombrew
if ! type "brew" >/dev/null 2>&1; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew bundle --file $(dirname $(realpath $0))/home/Brewfile
