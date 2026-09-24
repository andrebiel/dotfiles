brew "bun"
brew "fzf"
brew "gh"
brew "granted"
brew "steipete/tap/codexbar"
herdr_installed = File.executable?(File.expand_path("~/.local/bin/herdr")) ||
  ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |directory|
    File.executable?(File.join(directory, "herdr"))
  end
brew "herdr" unless herdr_installed
brew "jq"
brew "lazygit"
brew "neovim"
brew "nvm"
brew "jandedobbeleer/oh-my-posh/oh-my-posh"
brew "ripgrep"
brew "stow"
brew "tree-sitter-cli"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

cask "1password" unless File.directory?("/Applications/1Password.app")
cask "1password-cli"
# Oh My Posh needs a Nerd Font; the existing MesloLGS NF installation works well.
cask "font-meslo-for-powerlevel10k" unless File.exist?(File.expand_path("~/Library/Fonts/MesloLGS NF Regular.ttf"))
cask "ghostty"
