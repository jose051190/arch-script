#!/bin/bash

# Script para instalar ambiente Sway e Hyprland.

PACOTES=(
  sway
  swaybg
  kitty
  mako
  imv
  simple-scan
  zathura
  
  weechat
  wireplumber
  mpv
  swayidle
  grim
  slurp
  neovim
  newsboat
  swaylock
  waybar
)

echo "Atualizando sistema..."
sudo pacman -Syu

echo "Instalando pacotes oficiais..."
sudo pacman -S --needed "${PACOTES[@]}"

echo "Instalação concluída!"