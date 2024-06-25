#!/bin/bash

# Função para verificar o status dos comandos
check_command() {
  if [ $? -ne 0 ]; then
    echo "Erro ao executar: $1"
    exit 1
  fi
}

# Instalar Plasma e pacotes adicionais sem confirmação
sudo pacman -S --needed --noconfirm plasma-meta plasma-workspace konsole okular sddm xorg filelight ffmpeg ffmpegthumbs ffmpegthumbnailer nextcloud-client ttf-nerd-fonts-symbols elisa gwenview plymouth kwayland kwayland-integration konsole kwrite packagekit-qt6 ark egl-wayland dolphin dolphin-plugins xdg-desktop-portal-kde okular spectacle partitionmanager qt6-multimedia qt6-multimedia-gstreamer qt6-multimedia-ffmpeg qt6-wayland kdeplasma-addons kcalc plasma-systemmonitor kdeconnect kio-gdrive lokalize kde-dev-utils kompare ghostwriter knotes kclock timeshift neovim firefox-i18n-pt-br gparted plasma-firewall ttf-fira-sans ttf-roboto-mono-nerd ttf-fira-mono rclone telegram-desktop ufw fastfetch neofetch htop ncdu virt-manager qemu-desktop ebtables iptables-nft dnsmasq edk2-ovmf spice-vdagent virt-viewer alsa-lib alsa-plugins dosbox fontconfig gamemode giflib glfw gnutls goverlay gst-plugin-pipewire gst-plugin-va gst-plugins-bad gst-plugins-bad-libs gst-plugins-base gst-plugins-base-libs gst-plugins-good gst-plugins-ugly gtk2 gtk3 lib32-alsa-lib lib32-alsa-plugins lib32-fontconfig lib32-giflib lib32-gnutls lib32-gst-plugins-base-libs lib32-gst-plugins-good lib32-gtk3 lib32-libgcrypt lib32-libgpg-error lib32-libjpeg-turbo lib32-libldap lib32-libpng lib32-libpulse lib32-libva lib32-libva-mesa-driver lib32-libxcomposite lib32-libxinerama lib32-libxslt lib32-mangohud lib32-mpg123 lib32-ncurses lib32-ocl-icd lib32-openal lib32-sqlite lib32-v4l-utils lib32-vkd3d lib32-vulkan-icd-loader libgcrypt libgpg-error libjpeg-turbo libldap libpng libpulse libva libva-mesa-driver libxcomposite libxinerama libxslt lutris mangohud mpg123 ncurses ocl-icd openal opencl-icd-loader sqlite steam steam-native-runtime ttf-liberation v4l-utils vkd3d vulkan-icd-loader wine wine-gecko wine-mono wine-nine winetricks wqy-zenhei sane pycharm-community-edition ufw
check_command "pacman -S plasma-desktop e outros pacotes"

# Configurar GRUB para Plymouth
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&splash rd.udev.log_priority=3 vt.global_cursor_default=0 nvidia_drm.modeset=1 nvidia.NVreg_EnableGpuFirmware=0 /' /etc/default/grub
check_command "sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"/&splash rd.udev.log_priority=3 vt.global_cursor_default=0 nvidia_drm.modeset=1 nvidia.NVreg_EnableGpuFirmware=0 /' /etc/default/grub"

# Atualizar GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg
check_command "sudo grub-mkconfig -o /boot/grub/grub.cfg"

# Adicionar plymouth ao vetor HOOKS em mkinitcpio.conf após base e udev
sudo sed -i '/^HOOKS=/ s/\(base udev\)/\1 plymouth/' /etc/mkinitcpio.conf
check_command "sudo sed -i '/^HOOKS=/ s/\(base udev\)/\1 plymouth/' /etc/mkinitcpio.conf"

# Atualizar mkinitcpio
sudo mkinitcpio -p linux
check_command "sudo mkinitcpio -p linux"

# Ativação e início do serviço libvirtd
sudo systemctl enable --now libvirtd.service

# Habilitar SDDM
sudo systemctl enable sddm.service
check_command "sudo systemctl enable sddm.service"

# Habilitar Firewall
sudo systemctl enable ufw.service
check_command "sudo systemctl enable ufw.service"

# Perguntar ao usuário se deseja reiniciar
echo "Instalação do KDE Plasma e pacotes adicionais concluída. Deseja reiniciar o sistema agora? (s/n)"
read resposta

if [ "$resposta" == "s" ]; then
  echo "Reiniciando o sistema..."
  sudo reboot
else
  echo "Reinicialização cancelada. Por favor, reinicie o sistema manualmente para aplicar as alterações."
fi
