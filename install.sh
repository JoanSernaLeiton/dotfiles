#!/usr/bin/env bash

if [[ `uname` == "Linux"   ]]; then
  echo "Linux detected. Using Linux config..."
  echo "Installing zsh..."
  sudo apt install zsh
  echo "Changing shell to zsh"
  sudo chsh -s $(which zsh)
  # Adding homebrew to zprofile
  echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> /home/charlie/.zprofile
  eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
  echo "Installing PyEnv"
  curl https://pyenv.run | bash
fi

echo "Installing Oh my zsh"
 sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

echo '# Set PATH, MANPATH, etc., for Homebrew.' >> /Users/joanserna/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/joanserna/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

echo "Installing Python"
brew install python
pip3 install --user pipenv

echo "Removing existing dotfiles"
# remove files if they already exist
rm -rf ~/.config/nvim/coc-settings.json
rm -rf ~/.vim ~/.vimrc ~/.zshrc ~/.tmux ~/.tmux.conf ~/.config/nvim 2> /dev/null

echo "Creating symlinks"
# Neovim expects some folders already exist
mkdir -p ~/.config ~/.config/nvim ~/.config/nvim/lua


# Symlinking files
ln -s ~/dotfiles/zshrc ~/.zshrc
ln -s ~/dotfiles/tmux.conf ~/.tmux.conf
ln -s ~/dotfiles/kitty.conf ~/.config/kitty/kitty.conf
ln -s ~/dotfiles/init.lua ~/.config/nvim/init.lua
ln -s ~/dotfiles/nvim/lua ~/.config/nvim/lua
ln -s ~/dotfiles/nvim/after ~/.config/nvim/after
ln -s ~/dotfiles/coc-settings.json ~/.config/nvim/coc-settings.json

# Italics and true color profile for tmux
tic -x tmux.terminfo

brew install ripgrep
brew install tmux
brew install neovim
brew install ag
brew install fzf
brew install bat
brew install thefuck
brew install go
brew install llvm
brew install gcc
brew install gdb
brew install bazel
brew install cmake

# FORMATTERS
brew install shfmt
brew install clang-format

if [[ `uname` == "Linux"   ]]; then
  echo "Linux detected. Using Linux config..."
  echo "Installing JetBrains Mono"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/install_manual.sh)"
  echo "Installing pyenv"
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

# FZF shortcuts
$(brew --prefix)/opt/fzf/install

# install fnm
curl -fsSL https://fnm.vercel.app/install | bash

# install Paq - Neovim Plugin Manageri
git clone --depth=1 https://github.com/savq/paq-nvim.git \
    "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/pack/paqs/start/paq-nvim

pip3 install pynvim

# Go setup
mkdir -p $HOME/go/{bin,src,pkg}

# Writting vim will launch nvim
alias vim="nvim"
