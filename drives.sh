#!/bin/bash

# Função para verificar o status dos comandos
check_command() {
  if [ $? -ne 0 ]; then
    echo "Erro ao executar: $1"
    exit 1
  fi
}

# Instalar Plasma e pacotes adicionais sem confirmação
pacman -S --noconfirm plasma-desktop plasma-meta plasma-workspace konsole okular sddm xorg ffmpeg ffmpegthumbs ffmpegthumbnailer nextcloud-client ttf-nerd-fonts elisa gwenview plymouth kwayland kwayland-integration konsole kwrite packagekit-qt ark egl-wayland dolphin dolphin-plugins xdg-desktop-portal-kde okular spectacle partitionmanager qt6-multimedia qt6-multimedia-gstreamer qt6-multimedia-ffmpeg qt6-wayland kdeplasma-addons kcalc plasma-systemmonitor kdeconnect kio-gdrive lokalize kde-dev-utils kompare ghostwriter knotes kclock timeshift nvim
check_command "pacman -S plasma-desktop e outros pacotes"

# Configurar GRUB para Plymouth
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&splash rd.udev.log_priority=3 vt.global_cursor_default=0 nvidia_drm.modeset=1 nvidia.NVreg_EnableGpuFirmware=0 /' /etc/default/grub
check_command "sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"/&splash rd.udev.log_priority=3 vt.global_cursor_default=0 nvidia_drm.modeset=1 nvidia.NVreg_EnableGpuFirmware=0 /' /etc/default/grub"

# Atualizar GRUB
grub-mkconfig -o /boot/grub/grub.cfg
check_command "grub-mkconfig -o /boot/grub/grub.cfg"

# Habilitar SDDM
systemctl enable sddm.service
check_command "systemctl enable sddm.service"

# Finalizar
echo "Instalação do KDE Plasma e pacotes adicionais concluída. Rebootando o sistema..."
reboot