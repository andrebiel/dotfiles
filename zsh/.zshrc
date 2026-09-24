# Interactive non-login shells do not read ~/.zprofile.
source "$HOME/.config/zsh/homebrew.zsh"

# Child terminal tools must not inherit an old Herdr server's SHELL=/bin/bash.
export SHELL="$(command -v zsh)"

if (( $+commands[brew] )); then
  HOMEBREW_PREFIX="$(brew --prefix)"

  [[ -r "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [[ "$OSTYPE" == linux* ]]; then
  [[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Interactive aliases.
alias c='code'
alias pn='pnpm'
alias ls='ls -lha'
alias pa='php artisan'
alias assume='. assume'
alias python='python3'
alias pip='pip3'
alias gs='git status'
alias vim='nvim'
alias crd='composer run dev'
alias claude='claude --dangerously-skip-permissions'
alias codex='codex --dangerously-bypass-approvals-and-sandbox'

# Node via Homebrew's nvm package.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if (( $+commands[brew] )); then
  NVM_PREFIX="$(brew --prefix nvm 2>/dev/null)"
  [[ -r "$NVM_PREFIX/nvm.sh" ]] && source "$NVM_PREFIX/nvm.sh"
  [[ -r "$NVM_PREFIX/etc/bash_completion.d/nvm" ]] && source "$NVM_PREFIX/etc/bash_completion.d/nvm"
fi

if [[ "$OSTYPE" == linux* && -r "$NVM_DIR/nvm.sh" ]]; then
  source "$NVM_DIR/nvm.sh"
fi

# Preserve the existing pnpm global-bin location when it exists.
if [[ "$OSTYPE" == linux* ]]; then
  export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
else
  export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
fi
[[ -d "$PNPM_HOME" ]] && path=("$PNPM_HOME" $path)

# Bun and completions.
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
[[ -d "$BUN_INSTALL/bin" ]] && path=("$BUN_INSTALL/bin" $path)
[[ -r "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"

# Optional Laravel Herd installations.
if [[ -d "$HOME/.config/herd-lite/bin" ]]; then
  path=("$HOME/.config/herd-lite/bin" $path)
  export PHP_INI_SCAN_DIR="$HOME/.config/herd-lite/bin${PHP_INI_SCAN_DIR:+:$PHP_INI_SCAN_DIR}"
fi

HERD_SUPPORT="$HOME/Library/Application Support/Herd"
[[ -d "$HERD_SUPPORT/bin" ]] && path=("$HERD_SUPPORT/bin" $path)
[[ -d "$HERD_SUPPORT/config/php/83" ]] && export HERD_PHP_83_INI_SCAN_DIR="$HERD_SUPPORT/config/php/83/"
[[ -d "$HERD_SUPPORT/config/php/84" ]] && export HERD_PHP_84_INI_SCAN_DIR="$HERD_SUPPORT/config/php/84/"
[[ -d "$HERD_SUPPORT/config/php/85" ]] && export HERD_PHP_85_INI_SCAN_DIR="$HERD_SUPPORT/config/php/85/"
unset HERD_SUPPORT

# This is a path, not a credential. The JSON file itself is never tracked.
export GOOGLE_DRIVE_OAUTH_CREDENTIALS="$HOME/.config/google-drive-mcp/gcp-oauth.keys.json"

export PATH

# Syntax highlighting must be sourced after other plugins and widgets.
if (( $+commands[brew] )); then
  [[ -r "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] &&
    source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

if [[ "$OSTYPE" == linux* && -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

unset HOMEBREW_PREFIX NVM_PREFIX

# Keep prompt initialization last so it can install its Zsh hooks cleanly.
if (( $+commands[oh-my-posh] )); then
  eval "$(oh-my-posh init zsh --strict --config "$HOME/.config/oh-my-posh/shell.omp.json")"
fi
