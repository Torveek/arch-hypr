#!/bin/bash

##############################################################
# Hyprland Setup Script
# Based on your Start_system_setup.sh, this script installs
# Hyprland and its dependencies and configures Hyprland tools.
##############################################################

# Helper functions
print_message() {
    echo -e "\033[0;32m[*]\033[0m $1"
}
print_warning() {
    echo -e "\033[1;33m[!]\033[0m $1"
}
print_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}
execute_command() {
    local cmd="$1"
    local description="$2"
    print_message "$description"
    if eval "$cmd"; then
        return 0
    else
        print_error "Command failed: $cmd"
        return 1
    fi
}

# New function to check and prompt user input for required variables
check_user_input() {
    # Check if WALLPAPER_DIR is set, prompt if not
    if [ -z "$WALLPAPER_DIR" ]; then
        echo "WARNING: WALLPAPER_DIR is not set."
        read -p "Please enter the path to your wallpaper directory: " input_wallpaper_dir
        export WALLPAPER_DIR="$input_wallpaper_dir"
    fi

    # Check if MONITORS variable is set, prompt if not
    if [ -z "$MONITORS" ]; then
        echo "WARNING: MONITORS variable is not set."
        echo "Please enter your monitor names separated by spaces, check with 'hyprctl monitors' (eg: \"DP-1 HDMI-A-1\"): "
        read -r input_monitors
        # Convert input into an array and export it
        export MONITORS=($input_monitors)
    fi
}

# New function to update configuration files with user input
update_configs() {
    # Update the wallpaper configuration file
    local wallpaper_conf="$HOME/arch-hypr/dotfiles/.config/hypr/sources/change_wallpaper.conf"
    mkdir -p "$(dirname "$wallpaper_conf")"
    {
        echo "# Wallpaper Configuration"
        echo "WALLPAPER_DIR=\"$WALLPAPER_DIR\""
    } > "$wallpaper_conf"
    
    # Update the display configuration file with each monitor details
    local displays_conf="$HOME/arch-hypr/dotfiles/.config/hypr/sources/displays.conf"
    mkdir -p "$(dirname "$displays_conf")"
    {
        echo "# Display Configuration"
        for monitor in "${MONITORS[@]}"; do
            # Prompt for resolution and refresh rate for each monitor
            read -p "Enter resolution for monitor ${monitor} [2560x1440]: " res
            res=${res:-2560x1440}
            read -p "Enter refresh rate for monitor ${monitor} [144]: " refresh
            refresh=${refresh:-144}
            # Here, position is fixed; adjust as necessary
            echo "monitor=${monitor},${res}@${refresh},0x0,1"
        done
    } > "$displays_conf"
    cp -r "$HOME/arch-hypr/dotfiles/Wallpaper/* $WALLPAPER_DIR
    print_message "Configuration files updated with user input."
}

##############################################################
# Pacman Update and Hyprland Packages Installation
##############################################################

# Array of Hyprland-related pacman packages
hyprland_packages=(
    # Core Hyprland packages
    "hyprland"
    "waybar"
    "hyprpaper"
    "hyprcursor"
    "wofi"
    "hyprlock"
    "hypridle"
    "hyprpolkitagent"
    
    # File Management
    # "dolphin"
    "thunar"
    "git"
    "fd"
    "fzf"
    # "stow"
    
    # Terminal and Shell
    "kitty"
    "fish"
    
    # Browser
    # "vivaldi"
    
    # System Integration
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-gtk"
    "polkit-kde-agent"
    "gnome-keyring"
    "network-manager-applet"
    "networkmanager"
    "nm-connection-editor"
    
    # Notifications
    "dunst"
    
    # Theming and Appearance
    "ttf-jetbrains-mono-nerd"
    "rose-pine-hyprcursor"
    "cava"
    
    # CLI Tools
    "bat"
    "lsd"
    "btop"
)

install_pacman_packages() {
    print_message "Updating pacman database..."
    execute_command "sudo pacman -Sy" "Update pacman database" || exit 1

    print_message "Installing Hyprland packages..."
    for pkg in "${hyprland_packages[@]}"; do
        if ! execute_command "sudo pacman -S --needed --noconfirm $pkg" "Installing $pkg"; then
            print_warning "Failed to install $pkg. Please install manually if issues persist."
        fi
    done
}

##############################################################
# AUR Extras Installation
##############################################################

# Array of AUR packages
aur_extras=(
    "xwaylandvideobridge-git"
    "hyprshot"
    # "visual-studio-code-bin"
    "waterfox-bin"
)

install_aur_extras() {
    print_message "Installing Hyprland AUR extras: ${aur_extras[*]}"
    for pkg in "${aur_extras[@]}"; do
        if ! execute_command "yay -S --needed --noconfirm $pkg" "Install $pkg"; then
            print_warning "Installation of $pkg failed. Please install manually."
        fi
    done
}

##############################################################
# Hyprland Configurations
##############################################################

# Check if Hyprland is running
check_hyprland() {
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
        return 0
    else
        return 1
    fi
}

##############################################################
# Main Execution Flow
##############################################################
main() {
    print_message "Starting Hyprland Setup..."
    check_user_input
    update_configs
    install_pacman_packages
    install_aur_extras

    # Copy dotfiles 
    printf " Copying config files...\n"
    cp -r "$HOME/arch-hypr/dotfiles/.config/* ~/.config/ 

    print_message "Hyprland setup completed successfully!"
}

main
