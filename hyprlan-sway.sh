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
  kvantum
  kvantum-qt5
  font-manager
  wev
  sway
  swaybg
  kitty
  mako
  imv
  fuzzel
  wofi
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
