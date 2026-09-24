# Shared by Bash and Zsh. Keep this file silent and compatible with both shells.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export EDITOR='nvim'
export VISUAL='nvim'

# Non-interactive Bash children read this file too.
export BASH_ENV="$HOME/.config/zsh/environment.sh"

# One machine-local secrets file; never copy its values into the repository.
if [ -r "$HOME/.config/zsh/secrets.zsh" ]; then
  . "$HOME/.config/zsh/secrets.zsh"
fi
