# Create global taskfile
if [ ! -f ~/Taskfile.yaml ]; then
	echo blash
	cat <<-EOF > ~/Taskfile.yaml
	version: '3'

	includes:
	dotfiles:
		taskfile: $(dirname $(realpath $0))/Taskfile.yaml
		flatten: true
	EOF
fi

if [[ -f /etc/os-release ]]; then
	source /etc/os-release
fi

if [[ "$OSTYPE" =~ ^darwin ]]; then
	ln -sf $(dirname $(realpath $0))/package/Brewfile ~/Brewfile

	if ! type "bash" >/dev/null 2>&1; then
		# Install hombrew
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi
	
	if ! type "task" >/dev/null 2>&1; then
		brew install go-task
	fi
fi

# if [[ "$ID" == "opensuse-tumbleweed" ]]; then
# 	# TODO
# fi
