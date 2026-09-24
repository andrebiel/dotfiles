# Zsh loads this for every shell, including non-interactive SSH commands.
if [ -r "$HOME/.config/zsh/environment.sh" ]; then
  . "$HOME/.config/zsh/environment.sh"
fi
