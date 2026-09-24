# Shared by login and interactive non-login Zsh sessions.
if (( ! $+commands[brew] )); then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

typeset -U path PATH
path=("$HOME/.local/bin" $path)
export PATH
