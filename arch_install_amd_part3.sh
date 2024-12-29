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
  sudo pacman -S --needed plasma-meta plasma-workspace konsole okular wl-clipboard npm fwupd fzf xdg-desktop-portal-gtk power-profiles-daemon sddm xorg-xwayland syncthing filelight ffmpeg ffmpegthumbs ffmpegthumbnailer kdegraphics-thumbnailers kdenetwork-filesharing cifs-utils powerdevil sonnet kwallet kscreen nextcloud-client ttf-nerd-fonts-symbols inter-font ttf-jetbrains-mono elisa gwenview plymouth kwayland kwayland-integration kfind xwaylandvideobridge konsole kwrite ark egl-wayland dolphin dolphin-plugins breeze-gtk kde-gtk-config plasma-pa xdg-desktop-portal-kde spectacle partitionmanager qt6-multimedia qt6-multimedia-gstreamer qt6-multimedia-ffmpeg qt6-wayland kdeplasma-addons kalk sweeper krename plasma-systemmonitor kdeconnect kio-gdrive lokalize kde-dev-utils kompare ghostwriter kclock neovim plasma-firewall ttf-fira-sans ttf-roboto-mono-nerd ttf-fira-mono rclone fastfetch htop ncdu virt-manager qemu-full ebtables iptables-nft dnsmasq edk2-ovmf spice-vdagent firewalld chromium flatpak zram-generator wl-clipboard cryfs pacman-contrib pacutils expac less ksystemlog rsync ncdu sshfs go docker docker-compose toolbox cronie
  check_command "pacman -S plasma-desktop e outros pacotes"

  # Habilitar SDDM
  sudo systemctl enable sddm.service
  check_command "sudo systemctl enable sddm.service"
  
elif [ "$desktop_choice" == "2" ]; then
  # Instalar GNOME e pacotes adicionais sem confirmação
  sudo pacman -S --needed gnome gnome-tweaks xorg-xwayland wl-clipboard fwupd ffmpeg ffmpegthumbnailer fzf nextcloud-client ttf-nerd-fonts-symbols inter-font ttf-jetbrains-mono plymouth xdg-desktop-portal-gnome neovim firefox-i18n-pt-br ttf-fira-sans ttf-roboto-mono-nerd ttf-fira-mono rclone telegram-desktop fastfetch htop ncdu virt-manager qemu-full ebtables iptables-nft dnsmasq edk2-ovmf spice-vdagent pycharm-community-edition firewalld chromium
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
sudo sed -i '/^HOOKS=/ s/\(base udev\)/\1 plymouth/' /etc/mkinitcpio.conf
check_command "sudo sed -i '/^HOOKS=/ s/\(base udev\)/\1 plymouth/' /etc/mkinitcpio.conf"

# Atualizar mkinitcpio
sudo mkinitcpio -p linux
check_command "sudo mkinitcpio -p linux"

# Ativação e início do serviço libvirtd
sudo systemctl enable --now libvirtd.service
check_command "sudo systemctl enable --now libvirtd.service"

# Habilitar Firewall
sudo systemctl enable firewalld.service
check_command "sudo systemctl enable firewalld.service"

# Iniciar o serviço syncthing
sudo systemctl enable syncthing@jose.service

# Iniciar o serviço cronie
sudo systemctl enable cronie.service

# Iniciar e habilitar serviços do Docker
sudo systemctl enable docker.socket
sudo systemctl enable docker.service

# Instalar yay
cd /tmp/
git clone https://aur.archlinux.org/yay.git
check_command "git clone https://aur.archlinux.org/yay.git"
cd yay
makepkg -si --noconfirm
check_command "makepkg -si"


# Criar o arquivo de configuração do Zram
sudo bash -c 'cat > /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = ram
compression-algorithm = zstd
EOF'

# Criar arquivo de swapfile
sudo touch /swapfile
sudo chattr +C /swapfile  # Desativa o COW
sudo fallocate -l 1G /swapfile  # Cria o arquivo de 1 GB
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Recarregar o systemd
sudo systemctl daemon-reload

# Configuração do sysctl para parâmetros Zram
sudo bash -c 'cat > /etc/sysctl.d/99-vm-zram-parameters.conf <<EOF
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF'

# Aplicar as novas configurações sysctl
sudo sysctl --system

echo "Configuração do Zram finalizada."

# Reiniciar o serviço systemd-binfmt
sudo systemctl restart systemd-binfmt


# Ajustar Hora
sudo systemctl enable systemd-timesyncd.service
sudo systemctl start systemd-timesyncd.service

# Adicionar usuário aos grupos Docker e Libvirt
sudo usermod -aG docker $USER
sudo usermod -aG libvirt $USER

# Perguntar ao usuário se deseja reiniciar
echo "Instalação concluída. Deseja reiniciar o sistema agora? (s/n)"
read resposta

if [ "$resposta" == "s" ]; then
  echo "Reiniciando o sistema..."
  sudo reboot
else
  echo "Reinicialização cancelada. Por favor, reinicie o sistema manualmente para aplicar as alterações."
fi
