#!/bin/bash

# Link zsh
ln -sf ~/dotfiles/zsh/config ~/.zshrc

# Link neovim
rm -rf ~/.config/nvim
ln -sf ~/dotfiles/nvim ~/.config



