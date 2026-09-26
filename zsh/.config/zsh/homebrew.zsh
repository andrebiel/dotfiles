# Shared by login and interactive non-login Zsh sessions.
# Always run shellenv: an inherited PATH may list Homebrew after /usr/bin,
# which would let macOS tools (e.g. Python 3.9) shadow Homebrew's.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

typeset -U path PATH fpath FPATH
path=("$HOME/.local/bin" $path)
export PATH
