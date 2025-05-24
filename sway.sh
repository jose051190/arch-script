#!/bin/bash

# Script para instalar ambiente Sway usando apenas pacotes oficiais do Arch Linux

PACOTES=(
  sway
  kitty
  dunst
  imv
  simple-scan
  zathura
  weechat
  pipewire
  pipewire-alsa
  pipewire-jack
  pipewire-pulse
  wireplumber
  btop
  qutebrowser
  mpv
  swayidle
  grim
  slurp
  ranger
  neovim
  newsboat
  yt-dlp
  swaylock
  waybar
)

echo "Atualizando sistema..."
sudo pacman -Syu

echo "Instalando pacotes oficiais..."
sudo pacman -S --needed "${PACOTES[@]}"

echo "Instalação concluída!"

echo ""
echo "Para instalar o 'rofi-lbonn-wayland' (launcher compatível com Wayland), execute:"
echo "  yay -S rofi-lbonn-wayland"