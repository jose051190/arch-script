#!/bin/bash

# Script para instalar ambiente Sway e Hyprland.

PACOTES=(
  
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
  zathura-pdf-mupdf
  zathura-pdf-poppler
  simplenote
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
