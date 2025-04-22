#!/bin/bash

pkgs=(hyprland hyprpaper hyprpicker hyprcursor hyprutils hyprland hyprwayland-scanner aquamarine hyprgraphics hyprland-qtutils hyprlock xdg-desktop-portal-hyprland rsync hyprsysteminfo hyprpolkitagent hyprland-qt-support qt5ct qt6ct waybar rofi-wayland kitty dunst bibata-cursor-theme-bin tela-circle-icon-theme-blue-git qt5-wayland qt6-wayland xwaylandvideobridge copyq cliphist udiskie sddm darkly ttf-jetbrains-mono-nerd otf-font-awesome hyprshot thunar nwg-look)


is_arch_based() {
    source /etc/os-release

    if [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
        return 0
    elif command -v pacman >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function check () {
	sudo pacman -Qs --color always "$1" | grep "local" | grep "$1"
}

if ! is_arch_based; then
    echo "This script only supports Arch-based systems. Exiting."
    exit 1
fi

aur_helper=""
if check "paru"; then
	aur_helper="paru"
elif check "yay"; then
	aur_helper="yay"
else
	echo "No AUR helper found. Exiting."
	exit 1
fi

echo "Installing packages..."
$aur_helper -S --needed "${pkgs[@]}"

# copy configs

if ! git clone https://github.com/lawnclppings/dotfiles.git /tmp/dotfiles; then
    echo "Failed to clone dotfiles repo. Exiting."
    exit 1
fi

# backup existing confs if any
timestamp=$(date +%s)
backup_dir="$HOME/dotfiles-backup-$timestamp"


mkdir -p "$backup_dir/.config" "$backup_dir/.local/share"

for dir in /tmp/dotfiles/.config/*; do
    if [ -d "$dir" ]; then
        dir_name=$(basename "$dir")

        # Check if directory exists in $HOME/.config
        if [ -d "$HOME/.config/$dir_name" ]; then
            echo "Backing up $dir_name from .config to $backup_dir..."
            rsync -a --backup --backup-dir="$backup_dir/.config/$dir_name" "$dir/" "$HOME/.config/$dir_name/"
        fi
    fi
done

for dir in /tmp/dotfiles/.local/share/*; do
    if [ -d "$dir" ]; then
        dir_name=$(basename "$dir")

        # Check if directory exists in $HOME/.local/share
        if [ -d "$HOME/.local/share/$dir_name" ]; then
            echo "Backing up $dir_name from .local/share to $backup_dir..."
            rsync -a --backup --backup-dir="$backup_dir/.local/share/$dir_name" "$dir/" "$HOME/.local/share/$dir_name/"
        fi
    fi
done

# clone files from repo
mkdir -p "$HOME/.config" "$HOME/.local/share" "$HOME/.wallpapers"
cp -rf /tmp/dotfiles/.config/* "$HOME/.config/"
cp -rf /tmp/dotfiles/.local/share/* "$HOME/.local/share/"
cp -rf /tmp/dotfiles/.wallpapers/* "$HOME/.wallpapers/"


# SDDM
if [ -d /tmp/dotfiles/sddm-theme/catppuccin-mocha ]; then
    sudo mkdir -p /usr/share/sddm/themes/
    sudo cp -rf /tmp/dotfiles/sddm-theme/catppuccin-mocha /usr/share/sddm/themes/
    echo "[Theme]
Current=catppuccin-mocha" | sudo tee /etc/sddm.conf
fi

# reboot when finish install
read -p "Install completed. Reboot? [y/N]: " confirm
case "$confirm" in
	[yY][eE][sS]|[yY])
		reboot
		;;
	*)
		exit 1
		;;
esac
