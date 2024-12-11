#!/usr/bin/env bash

if [[ `uname` == "Linux"   ]]; then
  echo "Linux detected. Using Linux config..."
  echo "Installing zsh..."
  sudo apt install zsh -y
  echo "Changing shell to zsh"
  sudo chsh -s $(which zsh)
  echo "Installing curl"
  sudo apt install curl -y
  echo "Installing homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo "Adding homebrew to PATH"
  (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/joanserna/.zshrc
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  sudo apt-get install build-essential -y
  brew install gcc
fi

echo "Installing Oh my zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing Python"
brew install python
python3.11 -m pip install --upgrade pip
pip install --user pipenv

echo "Removing existing dotfiles"
rm -rf ~/.zshrc


 
echo "Creating symlinks"

# Neovim expects some folders already exist
mkdir -p ~/.config ~/.config/nvim ~/.config/nvim/lua ~/.config/kitty


# Symlinking files
ln -s ~/dotfiles/zshrc ~/.zshrc
ln -s ~/dotfiles/tmux.conf ~/.tmux.conf
ln -s ~/dotfiles/kitty.conf ~/.config/kitty/kitty.conf
ln -s ~/dotfiles/theme.conf ~/.config/kitty/theme.conf
ln -s ~/dotfiles/kitty-themes ~/.config/kitty/kitty-themes
ln -s ~/dotfiles/init.lua ~/.config/nvim/init.lua
ln -s ~/dotfiles/nvim/lua/ ~/.config/nvim/
ln -s ~/dotfiles/nvim/after ~/.config/nvim/after
ln -s ~/dotfiles/coc-settings.json ~/.config/nvim/coc-settings.json

echo "installing Kitty terminal"
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
# Italics and true color profile for tmux

brew install ripgrep
brew install tmux
brew install neovim
brew install ag
brew install fzf
brew install bat
brew install go
brew install gcc
brew install bazel
brew install cmake

# FORMATTERS
brew install shfmt

if [[ `uname` == "Linux"   ]]; then
  echo "Linux detected. Using Linux config..."
  echo "Installing JetBrains Mono"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/install_manual.sh)"
fi

if [[ `uname` == "Darwin"   ]]; then
  echo "Mac detected. Using Mac config..."

  # disable key repeat
  defaults write -g ApplePressAndHoldEnabled -bool false

  brew tap homebrew/cask-fonts

  # casks only work in mac
  brew install --cask font-fira-code
  brew install --cask font-jetbrains-mono
  brew install --cask font-meslo-lg-nerd-font
  brew install --cask font-iosevka
  brew install --cask rectangle

  brew install deno # deno brew formula only works with mac
  brew install reattach-to-user-namespace
fi

echo "Installing power level 10k"
brew install powerlevel10k
echo "source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme" >>~/.zshrc
echo "Installing zsh-syntax-highlighting"
brew install zsh-syntax-highlighting
source /home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
echo "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc

echo "Installing zsh-autosuggestions"
brew install zsh-autosuggestions
source /home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
echo "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc

# FZF shortcuts
$(brew --prefix)/opt/fzf/install

# install fnm
curl -fsSL https://fnm.vercel.app/install | bash

pip3 install pynvim

# Go setup
mkdir -p $HOME/go/{bin,src,pkg}

# Writting vim will launch nvim
alias vim="nvim"
