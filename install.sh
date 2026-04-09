#!/bin/bash
# Hyprlust dotfiles installer for Arch Linux

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ──────────────────────────────────────────────
# 1. Check we are on Arch
# ──────────────────────────────────────────────
if [[ ! -f /etc/arch-release ]]; then
    error "This script is for Arch Linux only."
fi

# ──────────────────────────────────────────────
# 2. Install AUR helper (yay) if missing
# ──────────────────────────────────────────────
install_yay() {
    if command -v yay &>/dev/null; then
        success "yay already installed"
        return
    fi
    info "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel
    local tmp
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp/yay"
    (cd "$tmp/yay" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    success "yay installed"
}

# ──────────────────────────────────────────────
# 3. Pacman packages
# ──────────────────────────────────────────────
PACMAN_PKGS=(
    # Hyprland core
    hyprland
    hyprlock
    hypridle
    hyprpicker
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk

    # Wayland essentials
    wayland
    wayland-utils
    xorg-xwayland

    # Bar / notifications / app launcher
    waybar
    rofi-wayland
    swaync

    # Terminal
    kitty

    # Audio (pipewire stack)
    pipewire
    pipewire-pulse
    pipewire-alsa
    pipewire-jack
    wireplumber
    pamixer
    playerctl

    # Clipboard
    wl-clipboard
    cliphist

    # Screenshot
    grim
    slurp
    swappy

    # Brightness
    brightnessctl

    # System tray / polkit
    network-manager-applet
    polkit-gnome

    # Notifications
    libnotify

    # File manager / utils
    yazi
    jq
    imagemagick
    xdg-user-dirs
    python
    python-pip

    # Theming - Qt
    qt5ct
    qt6ct
    kvantum

    # Theming - GTK
    nwg-look

    # Terminal tools
    btop
    fastfetch
    neovim

    # Media
    mpv
    mpd
    mpc

    # Document viewer
    zathura
    zathura-pdf-mupdf

    # Fonts (nerd fonts for waybar/rofi icons)
    ttf-jetbrains-mono-nerd
    ttf-nerd-fonts-symbols
    noto-fonts
    noto-fonts-emoji
)

install_pacman_pkgs() {
    info "Installing pacman packages..."
    sudo pacman -Syu --needed --noconfirm "${PACMAN_PKGS[@]}"
    success "Pacman packages installed"
}

# ──────────────────────────────────────────────
# 4. AUR packages
# ──────────────────────────────────────────────
AUR_PKGS=(
    # Wallpaper color theming
    wallust

    # Adaptive theming (matugen)
    matugen-bin

    # Pyprland (scratchpad / pypr daemon)
    pyprland

    # iio-hyprland (auto rotate for laptops/tablets)
    iio-hyprland

    # AGS (Aylur's GTK Shell — used for overview)
    ags

    # Logout menu
    wlogout

    # Cava (audio visualizer for waybar)
    cava

    # mpDris2 (MPRIS bridge for mpd)
    mpdris2

    # Calculator (used by rofi RofiCalc)
    qalculate-gtk

    # Wallpaper daemon (awww — swww replacement)
    awww
)

install_aur_pkgs() {
    info "Installing AUR packages..."
    yay -S --needed --noconfirm "${AUR_PKGS[@]}"
    success "AUR packages installed"
}

# ──────────────────────────────────────────────
# 5. Enable user services
# ──────────────────────────────────────────────
enable_services() {
    info "Enabling user services..."
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
    success "Services enabled"
}

# ──────────────────────────────────────────────
# 6. Copy dotfiles
# ──────────────────────────────────────────────
copy_dotfiles() {
    info "Backing up existing ~/.config entries..."
    local backup_dir="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"

    # Only back up folders we are about to overwrite
    local dirs=(
        hypr waybar rofi kitty swaync
        btop fastfetch mpv mpd nvim yazi
        qt5ct qt6ct Kvantum wallust matugen
        BeatPrints wlogout swappy
    )
    mkdir -p "$backup_dir"
    for d in "${dirs[@]}"; do
        if [[ -d "$HOME/.config/$d" ]]; then
            cp -r "$HOME/.config/$d" "$backup_dir/$d"
        fi
    done
    success "Backup saved to $backup_dir"

    info "Copying dotfiles to ~/.config..."
    cp -r "$DOTFILES_DIR/.config/." "$HOME/.config/"
    success "Dotfiles copied"
}

# ──────────────────────────────────────────────
# 7. Create required directories
# ──────────────────────────────────────────────
create_dirs() {
    info "Creating required directories..."
    mkdir -p "$HOME/Pictures/wallpapers"
    mkdir -p "$HOME/Pictures/Screenshots"
    xdg-user-dirs-update
    success "Directories created"
}

# ──────────────────────────────────────────────
# 8. Make scripts executable
# ──────────────────────────────────────────────
make_scripts_executable() {
    info "Making scripts executable..."
    find "$HOME/.config/hypr/scripts" "$HOME/.config/hypr/UserScripts" \
        -type f -name "*.sh" -exec chmod +x {} \;
    success "Scripts are executable"
}

# ──────────────────────────────────────────────
# 9. Hyprland plugins via hyprpm
# ──────────────────────────────────────────────
setup_hyprpm() {
    info "Setting up hyprpm plugins..."
    # hyprgrass must be installed via hyprpm to avoid -git library conflicts
    # It can only run inside a Hyprland session, so we print instructions instead
    warn "hyprgrass (touch gestures) must be installed inside a Hyprland session."
    echo "  After first login, run these two commands:"
    echo "    hyprpm add https://github.com/horriblename/hyprgrass"
    echo "    hyprpm enable hyprgrass"
}

# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────
echo ""
echo -e "${CYAN}==============================${NC}"
echo -e "${CYAN}  Hyprlust Arch Linux Installer${NC}"
echo -e "${CYAN}==============================${NC}"
echo ""

install_yay
install_pacman_pkgs
install_aur_pkgs
enable_services
copy_dotfiles
create_dirs
make_scripts_executable
setup_hyprpm

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Installation complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Put wallpapers in: ~/Pictures/wallpapers"
echo "  2. Log out and select Hyprland from your display manager"
echo "  3. On first boot, run: hyprpm reload"
echo ""
warn "If you are on a laptop you may want to keep iio-hyprland. If desktop, you can ignore it."
echo ""
