#!/bin/bash

# Função para verificar o status dos comandos
check_command() {
  if [ $? -ne 0 ]; then
    echo "Erro ao executar: $1"
    exit 1
  fi
}

# Perguntar ao usuário se deseja instalar Plasma ou GNOME
echo "Qual ambiente de desktop deseja instalar? (Digite 1 para Plasma ou 2 para GNOME)"
read desktop_choice

if [ "$desktop_choice" == "1" ]; then
  # Instalar Plasma e pacotes adicionais sem confirmação
  sudo pacman -S --needed plasma-meta plasma-workspace konsole okular sddm xorg-xwayland filelight ffmpeg ffmpegthumbs ffmpegthumbnailer nextcloud-client ttf-nerd-fonts-symbols inter-font ttf-jetbrains-mono elisa gwenview plymouth kwayland kwayland-integration kfind xwaylandvideobridge konsole kwrite packagekit-qt6 ark egl-wayland dolphin dolphin-plugins xdg-desktop-portal-kde okular spectacle partitionmanager qt6-multimedia qt6-multimedia-gstreamer qt6-multimedia-ffmpeg qt6-wayland kdeplasma-addons kalk sweeper krename plasma-systemmonitor kdeconnect kio-gdrive lokalize kde-dev-utils kompare ghostwriter kclock neovim firefox-i18n-pt-br plasma-firewall ttf-fira-sans ttf-roboto-mono-nerd ttf-fira-mono rclone telegram-desktop fastfetch htop ncdu virt-manager qemu-full ebtables iptables-nft dnsmasq edk2-ovmf spice-vdagent virt-viewer pycharm-community-edition firewalld
  check_command "pacman -S plasma-desktop e outros pacotes"

  # Habilitar SDDM
  sudo systemctl enable sddm.service
  check_command "sudo systemctl enable sddm.service"
  
elif [ "$desktop_choice" == "2" ]; then
  # Instalar GNOME e pacotes adicionais sem confirmação
  sudo pacman -S --needed gnome xorg-xwayland ffmpeg ffmpegthumbs ffmpegthumbnailer nextcloud-client ttf-nerd-fonts-symbols inter-font ttf-jetbrains-mono plymouth xdg-desktop-portal-gnome neovim firefox-i18n-pt-br ttf-fira-sans ttf-roboto-mono-nerd ttf-fira-mono rclone telegram-desktop fastfetch htop ncdu virt-manager qemu-full ebtables iptables-nft dnsmasq edk2-ovmf spice-vdagent virt-viewer pycharm-community-edition firewalld
  check_command "pacman -S gnome e outros pacotes"

  # Habilitar GDM
  sudo systemctl enable gdm.service
  check_command "sudo systemctl enable gdm.service"
  
else
  echo "Opção inválida. Por favor, escolha 1 para Plasma ou 2 para GNOME."
  exit 1
fi

# Configurar GRUB para Plymouth
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&splash rd.udev.log_priority=3 vt.global_cursor_default=0 /' /etc/default/grub
check_command "sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"/&splash rd.udev.log_priority=3 vt.global_cursor_default=0 /' /etc/default/grub"

# Atualizar GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg
check_command "sudo grub-mkconfig -o /boot/grub/grub.cfg"

# Adicionar plymouth ao vetor HOOKS em mkinitcpio.conf após base e udev
sudo sed -i '/^HOOKS=/ s/base udev/\1 plymouth/' /etc/mkinitcpio.conf
check_command "sudo sed -i '/^HOOKS=/ s/base udev/\1 plymouth/' /etc/mkinitcpio.conf"

# Atualizar mkinitcpio
sudo mkinitcpio -p linux
check_command "sudo mkinitcpio -p linux"

# Ativação e início do serviço libvirtd
sudo systemctl enable --now libvirtd.service
check_command "sudo systemctl enable --now libvirtd.service"

# Habilitar Firewall
sudo systemctl enable firewalld.service
check_command "sudo systemctl enable firewalld.service"

# Instalar yay
cd /tmp/
git clone https://aur.archlinux.org/yay.git
check_command "git clone https://aur.archlinux.org/yay.git"
cd yay
makepkg -si --noconfirm
check_command "makepkg -si"

# Perguntar ao usuário se deseja reiniciar
echo "Instalação concluída. Deseja reiniciar o sistema agora? (s/n)"
read resposta

if [ "$resposta" == "s" ]; then
  echo "Reiniciando o sistema..."
  sudo reboot
else
  echo "Reinicialização cancelada. Por favor, reinicie o sistema manualmente para aplicar as alterações."
fi