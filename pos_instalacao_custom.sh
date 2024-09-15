#!/bin/bash

# Criar as pastas em /mnt
sudo mkdir -p /mnt/Dados-NTFS /mnt/Dados-Btrfs /mnt/OneDrive /mnt/Windows /mnt/Backup /mnt/Nextcloud

# Ajustar permissões e dono das pastas
sudo chmod +x /mnt/Dados-NTFS /mnt/Dados-Btrfs /mnt/OneDrive /mnt/Windows /mnt/Backup /mnt/Nextcloud
sudo chown jose:jose /mnt/Dados-NTFS /mnt/Dados-Btrfs /mnt/OneDrive /mnt/Windows /mnt/Backup /mnt/Nextcloud

echo "Pastas criadas e permissões ajustadas."

# Instalar os pacotes do repositório oficial
sudo pacman -Syu --noconfirm steam lutris wine inter-font ttf-jetbrains-mono rsync ncdu ttf-inconsolata syncthing sshfs zram-generator npm kup docker docker-compose flatpak mangohud vorta goverlay cronie ksystemlog calibre wl-clipboard

echo "Pacotes oficiais instalados."

# Instalar pacotes AUR utilizando o yay
yay -S --noconfirm onlyoffice-bin pdfsam protontricks protonup-qt visual-studio-code-bin pcloud-drive heroic-games-launcher-bin

echo "Pacotes AUR instalados."

# Aplicativos nativefier
npm install -g nativefier

# Configurar Numlock no SDDM
sudo sed -i '/^\[General\]/a Numlock=on' /etc/sddm.conf

echo "Numlock configurado no SDDM."

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

# Iniciar serviço docker
sudo systemctl enable docker.socket
sudo systemctl enable docker.service

# Adicionar usario aos grupos Docker e Libvirt
sudo usermod -aG docker $USER
sudo usermod -aG libvirt $USER

# Iniciar o serviço Zram
sudo systemctl enable systemd-zram-setup@zram0.service

# Iniciar o serviço syncthing
sudo systemctl enable syncthing@jose.service

# Iniciar o serviço cronie
sudo systemctl enable cronie.service

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

echo "Serviço systemd-binfmt reiniciado."

echo "Script de pós-instalação concluído com sucesso!"
