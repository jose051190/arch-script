#!/bin/bash

# Função para verificar o status dos comandos
check_command() {
  if [ $? -ne 0 ]; então
    echo "Erro ao executar: $1"
    exit 1
  fi
}

# Resumo das ações que serão realizadas
echo "Este script irá realizar as seguintes ações:"
echo "1. Instalar Plasma e pacotes adicionais."
echo "2. Configurar o GRUB para usar Plymouth."
echo "3. Adicionar plymouth ao vetor HOOKS em mkinitcpio.conf."
echo "4. Atualizar GRUB e mkinitcpio."
echo "5. Habilitar SDDM."
echo "6. Instalar yay."

# Pedir confirmação ao usuário
echo "Deseja continuar com a instalação? (s/n)"
read confirmacao

if [ "$confirmacao" != "s" ]; então
  echo "Instalação cancelada."
  exit 0
fi

# Instalar Plasma e pacotes adicionais sem confirmação
sudo pacman -S --noconfirm plasma-desktop plasma-meta plasma-workspace konsole okular sddm xorg ffmpeg ffmpegthumbs ffmpegthumbnailer nextcloud-client ttf-nerd-fonts-symbols elisa gwenview plymouth kwayland kwayland-integration konsole kwrite packagekit-qt6 ark egl-wayland dolphin dolphin-plugins xdg-desktop-portal-kde okular spectacle partitionmanager qt6-multimedia qt6-multimedia-gstreamer qt6-multimedia-ffmpeg qt6-wayland kdeplasma-addons kcalc plasma-systemmonitor kdeconnect kio-gdrive lokalize kde-dev-utils kompare ghostwriter knotes kclock timeshift neovim
check_command "pacman -S plasma-desktop e outros pacotes"

# Configurar GRUB para Plymouth
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&splash rd.udev.log_priority=3 vt.global_cursor_default=0 nvidia_drm.modeset=1 nvidia.NVreg_EnableGpuFirmware=0 /' /etc/default/grub
check_command "sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"/&splash rd.udev.log_priority=3 vt.global_cursor_default=0 nvidia_drm.modeset=1 nvidia.NVreg_EnableGpuFirmware=0 /' /etc/default/grub"

# Atualizar GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg --noconfirm
check_command "sudo grub-mkconfig -o /boot/grub/grub.cfg --noconfirm"

# Adicionar plymouth ao vetor HOOKS em mkinitcpio.conf após base e udev
sudo sed -i '/^HOOKS=/ s/\(base udev\)/\1 plymouth/' /etc/mkinitcpio.conf
check_command "sudo sed -i '/^HOOKS=/ s/\(base udev\)/\1 plymouth/' /etc/mkinitcpio.conf"

# Atualizar mkinitcpio
sudo mkinitcpio -p linux
check_command "sudo mkinitcpio -p linux"

# Habilitar SDDM
sudo systemctl enable sddm.service
check_command "sudo systemctl enable sddm.service"

# Instalar yay
cd /tmp/
sudo git clone https://aur.archlinux.org/yay.git
check_command "git clone https://aur.archlinux.org/yay.git"
cd yay
sudo makepkg -si --noconfirm
check_command "makepkg -si"

# Perguntar ao usuário se deseja reiniciar
echo "Instalação do KDE Plasma e pacotes adicionais concluída. Deseja reiniciar o sistema agora? (s/n)"
read resposta

if [ "$resposta" == "s" ]; então
  echo "Reiniciando o sistema..."
  sudo reboot
else
  echo "Reinicialização cancelada. Por favor, reinicie o sistema manualmente para aplicar as alterações."
fi