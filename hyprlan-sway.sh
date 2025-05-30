#!/bin/bash

# Script para instalar ambiente Sway e Hyprland.

PACOTES=(
  hyprland
  hyprpaper
  xdg-desktop-portal-hyprland
  nwg-look
  qt5ct
  qt6ct
  qt5-wayland
  qt6-wayland
  qt5-graphicaleffects
  sddm
  sddm-kcm
  rofi-wayland
  gnome-calculator
  rmpc
  yt-dlp
  ueberzugpp
  eza
  bat
  mpd
  mpc 
  leafpad
  tumbler 
  thunar
  timidity++
  file-roller
  polkit-gnome
  thunar-media-tags-plugin 
  thunar-shares-plugin 
  thunar-media-tags-plugin 
  kvantum
  kvantum-qt5
  font-manager
  wev
  sway
  swaybg
  kitty
  mako
  imv
  wf-recorder
  zathura
  zathura-cb
  zathura-pdf-poppler
  mpv
  swayidle
  grim
  slurp
  neovim
  swaylock
  waybar
)

echo "Atualizando sistema..."
sudo pacman -Syu

echo "Instalando pacotes oficiais..."
sudo pacman -S --needed "${PACOTES[@]}"

echo "Instalação concluída!"
