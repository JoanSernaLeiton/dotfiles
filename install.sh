#!/usr/bin/env bash

set -e  # Exit on error

# Helper functions
setup_directories() {
    echo "Creating necessary directories..."
    mkdir -p ~/.config/{nvim,kitty} \
             ~/.local/share/nvim/{backup,swap,undo} \
             ~/go/{bin,src,pkg}
}

backup_existing_config() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    echo "Backing up existing Neovim configuration..."
    
    if [ -d ~/.config/nvim ]; then
        mv ~/.config/nvim ~/.config/nvim.bak.$timestamp
    fi
}

setup_neovim() {
    echo "Setting up Neovim configuration..."
    
    # Remove existing symlinks if they exist
    rm -f ~/.config/nvim/init.lua
    rm -rf ~/.config/nvim/lua
    rm -rf ~/.config/nvim/after
    
    # Create the necessary directories
    mkdir -p ~/.config/nvim/{lua,after}
    
    # Create symlinks for the main structure
    ln -sf ~/dotfiles/nvim/init.lua ~/.config/nvim/init.lua
    ln -sf ~/dotfiles/nvim/lua ~/.config/nvim/lua
    ln -sf ~/dotfiles/nvim/after ~/.config/nvim/after
    
    # Ensure correct permissions
    chmod 755 ~/.config/nvim
    chmod 644 ~/.config/nvim/init.lua
}

install_linux_dependencies() {
    echo "Linux detected. Installing dependencies..."
    sudo apt install zsh curl build-essential -y
    sudo chsh -s $(which zsh)
    
    # Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    brew install gcc
}

install_mac_dependencies() {
    echo "MacOS detected. Setting up Mac-specific configurations..."
    defaults write -g ApplePressAndHoldEnabled -bool false
    
    brew tap homebrew/cask-fonts
    brew install --cask font-fira-code \
                      font-jetbrains-mono \
                      font-meslo-lg-nerd-font \
                      font-iosevka \
                      rectangle
    
    brew install deno reattach-to-user-namespace
}

install_common_packages() {
    echo "Installing common packages..."
    
    # Core tools
    brew install python neovim tmux ripgrep fzf bat go gcc cmake bazel ag
    
    # Formatters
    brew install shfmt
    
    # Shell enhancements
    brew install powerlevel10k zsh-syntax-highlighting zsh-autosuggestions
    
    # Setup shell configurations
    echo "source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme" >> ~/.zshrc
    echo "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
    echo "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
}

setup_python() {
    echo "Setting up Python environment..."
    python3 -m pip install --upgrade pip
    pip install --user pipenv pynvim
}

main() {
    # Initial setup
    setup_directories
    backup_existing_config
    
    # OS-specific setup
    if [[ $(uname) == "Linux" ]]; then
        install_linux_dependencies
    elif [[ $(uname) == "Darwin" ]]; then
        install_mac_dependencies
    fi
    
    # Common installations
    install_common_packages
    setup_python
    
    # Neovim setup
    setup_neovim
    
    # Additional tools
    curl -fsSL https://fnm.vercel.app/install | bash
    $(brew --prefix)/opt/fzf/install
    
    # Create vim alias
    echo 'alias vim="nvim"' >> ~/.zshrc
    
    echo "Installation completed successfully!"
}

main "$@"
