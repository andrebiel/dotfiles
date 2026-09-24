# Sourced by bootstrap after its functions have been defined.
select_platform() {
  local detected choice
  case "$(uname -s)" in
    Darwin) detected=macos ;;
    Linux) detected=linux ;;
    *) fail "unsupported operating system: $(uname -s)" ;;
  esac
  PLATFORM="${DOTFILES_PLATFORM:-}"
  WITHOUT_SECRETS=false
  BOOTSTRAP_COMMAND=all
  local command_seen=false
  while (($#)); do
    case "$1" in
      --platform)
        (($# >= 2)) || fail '--platform needs macos or linux'
        PLATFORM="$2"; shift 2 ;;
      --without-secrets) WITHOUT_SECRETS=true; shift ;;
      --reload) USAGE_RELOAD=true; shift ;;
      -h|--help|help) usage; exit 0 ;;
      all|migrate|install|secrets|auth|integrations|usage|link|doctor)
        [[ "$command_seen" == false ]] || fail 'choose only one command'
        BOOTSTRAP_COMMAND="$1"; command_seen=true; shift ;;
      *) fail "unknown argument: $1" ;;
    esac
  done
  if [[ -z "$PLATFORM" && -t 0 && ( "$BOOTSTRAP_COMMAND" == all || "$BOOTSTRAP_COMMAND" == install || "$BOOTSTRAP_COMMAND" == migrate ) ]]; then
    printf 'Set up this machine as MacBook (macos) or Linux? [%s]: ' "$detected" >&2
    read -r choice || fail 'platform selection cancelled'
    PLATFORM="${choice:-$detected}"
  fi
  PLATFORM="${PLATFORM:-$detected}"
  case "$PLATFORM" in
    MacBook|macbook|Mac|mac|macos|1) PLATFORM=macos ;;
    Linux|linux|2) PLATFORM=linux ;;
    *) fail 'platform must be macos (MacBook) or linux' ;;
  esac
  if [[ "$PLATFORM" != "$detected" && ( "$BOOTSTRAP_COMMAND" == all || "$BOOTSTRAP_COMMAND" == install || "$BOOTSTRAP_COMMAND" == migrate ) ]]; then
    fail "selected $PLATFORM but this machine runs $detected; run setup on the target machine"
  fi
  [[ "${USAGE_RELOAD:-false}" == false || "$BOOTSTRAP_COMMAND" == usage ]] || fail '--reload is only valid with usage'
  [[ "$WITHOUT_SECRETS" == false || "$BOOTSTRAP_COMMAND" == all || "$BOOTSTRAP_COMMAND" == doctor ]] || fail '--without-secrets is only valid with all or doctor'
  export DOTFILES_PLATFORM="$PLATFORM"
  export PATH="$HOME/.local/bin:$PATH"
  if [[ "$PLATFORM" == linux ]]; then
    PACKAGES=(zsh nvim ssh herdr-linux)
    MANAGED_PATHS=(.zshenv .zprofile .zshrc .config/zsh/homebrew.zsh .config/zsh/environment.sh
      .config/oh-my-posh/base.omp.json .config/oh-my-posh/shell.omp.json
      .config/oh-my-posh/claude.omp.json .config/nvim/init.lua .ssh/config
      .config/herdr/config.toml .local/bin/herdr-fuzzy-open)
  fi
}

file_mode() {
  if [[ "$(uname -s)" == Darwin ]]; then stat -f '%Lp' "$1"; else stat -c '%a' "$1"; fi
}

authenticate_secrets() {
  need op
  need jq
  if op whoami >/dev/null 2>&1; then return; fi
  if [[ ! -t 0 ]]; then
    fail '1Password sign-in required. Run ./bootstrap auth in your terminal to sign in and render secrets. Use --without-secrets with all to install first.'
  fi
  printf 'Sign in to 1Password locally. Credentials are never stored in this repository.\n'
  if [[ "$(op account list --format=json | jq 'length')" == 0 ]]; then
    op account add
  fi
  eval "$(op signin)"
  op whoami >/dev/null || fail '1Password sign-in did not complete'
}

linux_doctor() {
  export PATH="$HOME/.bun/bin:$PATH"
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [[ -r "$NVM_DIR/nvm.sh" ]]; then
    set +u
    source "$NVM_DIR/nvm.sh"
    set -u
  fi
  local relative tool
  for relative in "${MANAGED_PATHS[@]}"; do
    [[ -L "$HOME/$relative" && "$(resolved_path "$HOME/$relative")" == "$(managed_source "$relative")" ]] || fail "incorrect link: $HOME/$relative"
  done
  for tool in zsh stow nvim node npm pnpm bun op oh-my-posh rg fzf gh granted tree-sitter git jq lazygit herdr herdr-fuzzy-open; do need "$tool"; done
  HERDR_CONFIG_PATH="$HOME/.config/herdr/config.toml" herdr config check >/dev/null || fail 'Herdr configuration check failed'
  local integration integration_status
  integration_status="$(herdr integration status)"
  for integration in "${HERDR_INTEGRATIONS[@]}"; do
    grep -Eq "^${integration}: current \\(v[0-9]+\\)" <<<"$integration_status" || fail "Herdr $integration integration is not current"
  done
  "$DOTFILES_DIR/scripts/install-herdr-skill" --check
  grep -Fqx 'default_shell = "/usr/bin/zsh"' "$HOME/.config/herdr/config.toml" || fail 'Herdr must start Zsh'
  zsh -n "$HOME/.zshrc"
  zsh -lic '
    set -e
    (( ${+functions[_zsh_autosuggest_start]} ))
    (( ${+functions[_zsh_highlight]} ))
    (( ${+functions[nvm]} ))
    [[ "$POSH_CONFIG" == "$HOME/.config/oh-my-posh/shell.omp.json" ]]
    node --version >/dev/null
    pnpm --version >/dev/null
    alias gs >/dev/null
    [[ ${aliases[vim]} == nvim ]]
    [[ ${aliases[claude]} == "claude --dangerously-skip-permissions" ]]
    [[ ${aliases[codex]} == "codex --dangerously-bypass-approvals-and-sandbox" ]]
    [[ "$SHELL" == */zsh ]]
  ' || fail 'Zsh runtime validation failed'
  nvim --headless --noplugin -i NONE '+lua if vim.v.errmsg ~= "" or vim.fn.has("nvim-0.12") ~= 1 or vim.g.colors_name ~= "catppuccin" then vim.cmd("cquit") end' +qa || fail 'Neovim configuration validation failed'
  ssh -G localhost >/dev/null 2>&1 || fail 'SSH configuration validation failed'
  jq -e --arg command "$CLAUDE_STATUSLINE_COMMAND" '.statusLine.command == $command' "$HOME/.claude/settings.json" >/dev/null || fail 'Claude status line is not configured'
  if [[ "$WITHOUT_SECRETS" == false ]]; then
    [[ -f "$HOME/.config/zsh/secrets.zsh" ]] || fail 'secrets are missing: run ./bootstrap auth'
    [[ "$(file_mode "$HOME/.config/zsh/secrets.zsh")" == 600 ]] || fail 'secrets must have mode 600'
    zsh -n "$HOME/.config/zsh/secrets.zsh"
    zsh -fc 'source "$HOME/.config/zsh/secrets.zsh"; for key in AI_COMMIT_HOOK_API_KEY STORYBLOK_MCP_TOKEN TODOIST_MCP_TOKEN NOTION_PRIVATE_TOKEN GOOGLE_CLOUD_CLIENT_KEY; do [[ -n "${(P)key}" ]] || exit 1; done' || fail 'a managed secret is empty'
  else
    printf 'Secrets verification skipped (--without-secrets); authentication remains pending.\n'
  fi
  printf 'Linux dotfiles checks passed. Desktop apps and macOS launchd jobs are not part of this profile.\n'
}
