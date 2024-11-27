#!/bin/bash

# Git-Relax Installation Script

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status messages
print_status() {
    echo -e "${GREEN}✓ ${1}${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}✗ ${1}${NC}"
}

# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}⚠ ${1}${NC}"
}

# Check Prerequisites
check_prerequisites() {
    echo "Checking required tools..."

    # Check Git
    if ! command_exists git; then
        print_error "Git is not installed"
        exit 1
    fi
    print_status "Git is installed"

    # Check GitHub CLI
    if ! command_exists gh; then
        print_warning "GitHub CLI (gh) is not installed"
        read -p "Would you like to install GitHub CLI? (y/n): " install_gh
        if [[ $install_gh == "y" ]]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                brew install gh
            elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
                sudo apt install gh
            else
                print_error "Unsupported OS for automatic GitHub CLI installation"
                exit 1
            fi
        fi
    fi
    print_status "GitHub CLI is installed"

    # Check Gum
    if ! command_exists gum; then
        print_warning "Gum is not installed"
        read -p "Would you like to install Gum? (y/n): " install_gum
        if [[ $install_gum == "y" ]]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                brew install charmbracelet/tap/gum
            elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
                sudo apt install gum
            else
                print_error "Unsupported OS for automatic Gum installation"
                exit 1
            fi
        fi
    fi
    print_status "Gum is installed"

    # Check Mods
    if ! command_exists mods; then
        print_warning "Mods is not installed"
        read -p "Would you like to install Mods? (y/n): " install_mods
        if [[ $install_mods == "y" ]]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                brew install charmbracelet/tap/mods
            elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
                # Add Linux installation method if available
                print_error "Mods installation for Linux not automated. Please install manually."
                exit 1
            else
                print_error "Unsupported OS for automatic Mods installation"
                exit 1
            fi
        fi
    fi
    print_status "Mods is installed"

    # Check OpenAI API Key
    if [[ -z "$OPENAI_API_KEY" ]]; then
        print_warning "OpenAI API Key is not set"
        read -p "Enter your OpenAI API Key: " openai_key
        if [[ -n "$openai_key" ]]; then
            echo "export OPENAI_API_KEY='$openai_key'" >> ~/.bashrc
            source ~/.bashrc
        else
            print_error "No API Key provided. Please set OPENAI_API_KEY manually."
            exit 1
        fi
    fi
    print_status "OpenAI API Key is configured"
}

# Create configuration directories
create_config_directories() {
    mkdir -p ~/.config/git-relax
    mkdir -p ~/.local/bin
    print_status "Configuration directories created"
}

# Install Git-Relax scripts
install_scripts() {
    # Copy main scripts
    cp git-relax.sh ~/.local/bin/git-relax
    cp git-relax.sh ~/.local/bin/git-r
    chmod +x ~/.local/bin/git-relax
    chmod +x ~/.local/bin/git-r
    print_status "Git-Relax scripts installed"

    # Copy default configuration
    cp config.sh ~/.config/git-relax/config.sh
    print_status "Default configuration copied"
}

# Update PATH
update_path() {
    # Check if PATH update already exists
    if ! grep -q "~/.local/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
        source ~/.bashrc
    fi
    print_status "PATH updated with ~/.local/bin"
}

# Main installation function
main() {
    echo "🚀 Git-Relax Installation Script 🚀"
    
    check_prerequisites
    create_config_directories
    install_scripts
    update_path

    echo -e "${GREEN}✨ Git-Relax successfully installed! ✨${NC}"
    echo "Run 'git-relax' or 'git-r' to get started."
}

# Run the installation
main
