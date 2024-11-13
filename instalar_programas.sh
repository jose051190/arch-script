#!/bin/bash

# Lista de pacotes Pacman para instalação
pacotes_pacman=(
    adw-gtk-theme amdvlk baobab base base-devel bash-completion bluez bluez-utils btrfs-progs
    chromium cronie dialog dnsmasq docker docker-compose dosfstools edk2-ovmf efibootmgr
    evince expac fastfetch ffmpeg ffmpegthumbnailer firewalld gdm git gnome-backgrounds
    gnome-calculator gnome-calendar gnome-characters gnome-clocks gnome-console
    gnome-control-center gnome-disk-utility gnome-keyring gnome-logs gnome-menus
    gnome-remote-desktop gnome-session gnome-settings-daemon gnome-shell
    gnome-system-monitor gnome-text-editor gnome-tweaks gnome-user-docs gnome-user-share
    grilo-plugins grub gst-plugin-pipewire gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google
    gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd htop intel-ucode
    inter-font iptables-nft less lib32-amdvlk lib32-libva-mesa-driver lib32-mesa
    lib32-mesa-vdpau lib32-pipewire lib32-vulkan-icd-loader lib32-vulkan-radeon
    libva-mesa-driver linux linux-firmware linux-headers loupe malcontent mesa-vdpau mtools
    nano nautilus ncdu neovim network-manager-applet networkmanager ntfs-3g os-prober
    pacman-contrib pacutils pipewire pipewire-alsa pipewire-jack pipewire-pulse plymouth
    pycharm-community-edition python-pip qemu-full rclone rsync rygel sof-firmware
    spice-vdagent sushi syncthing tecla toolbox totem ttf-fira-mono ttf-fira-sans
    ttf-jetbrains-mono ttf-nerd-fonts-symbols ttf-roboto-mono-nerd virt-manager
    vulkan-icd-loader vulkan-mesa-layers vulkan-radeon wget wireplumber wl-clipboard
    xdg-desktop-portal-gnome xdg-user-dirs xdg-user-dirs-gtk xdg-utils xorg-xwayland
    zram-generator
)

# Instala pacotes Pacman que não estão instalados
echo "Instalando pacotes com o Pacman..."
sudo pacman -S --needed "${pacotes_pacman[@]}"

# Lista de pacotes do AUR para instalação
pacotes_aur=(
    gnome-browser-connector-git
    nautilus-open-in-ptyxis
    ttf-roboto-slab
)

# Instala pacotes do AUR que não estão instalados
for pacote in "${pacotes_aur[@]}"; do
    if ! yay -Q "$pacote" &> /dev/null; then
        echo "Instalando $pacote do AUR..."
        yay -S "$pacote"
    else
        echo "$pacote já está instalado. Ignorando..."
    fi
done

# Adiciona o repositório Flathub se ainda não estiver configurado
if ! flatpak remote-list --user | grep -q "flathub"; then
    echo "Adicionando o repositório Flathub..."
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Lista de pacotes Flatpak para instalação
pacotes_flatpak=(
    com.hunterwittenborn.Celeste
    org.gnome.DejaDup
    org.gnome.Todo
    com.github.tchx84.Flatseal
    io.github.giantpinkrobots.flatsweep
    com.github.neithern.g4music
    org.gnome.FontManager
    com.heroicgameslauncher.hgl
    page.codeberg.libre_menu_editor.LibreMenuEditor
    com.nextcloud.desktopclient.nextcloud
    org.onlyoffice.desktopeditors
    com.vysp3r.ProtonPlus
    app.devsuite.Ptyxis
    org.gnome.Solanum
    com.valvesoftware.Steam
    org.telegram.desktop
    com.visualstudio.code
    com.borgbase.Vorta
    org.vinegarhq.Sober
)

# Instala pacotes Flatpak para o usuário atual, ignorando os já instalados
for pacote in "${pacotes_flatpak[@]}"; do
    if ! flatpak list --user | grep -q "$pacote"; then
        echo "Instalando $pacote para o usuário..."
        flatpak install --user -y flathub "$pacote" || flatpak install --user -y "$pacote"
    else
        echo "$pacote já está instalado. Ignorando..."
    fi
done

# Configurações adicionais
echo "Realizando configurações adicionais..."

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

# Iniciar e habilitar serviços do Docker
sudo systemctl enable docker.socket
sudo systemctl enable docker.service

# Adicionar usuário aos grupos Docker e Libvirt
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

# Configurar o backend do firewall do libvirtd para iptables
sudo bash -c 'echo "firewall_backend = \"iptables\"" >> /etc/libvirt/network.conf'

# Reiniciar o serviço libvirtd para aplicar a configuração
sudo systemctl restart libvirtd

echo "Configuração do firewall do libvirtd ajustada para iptables."

# Ajustar Hora
sudo systemctl enable systemd-timesyncd.service
sudo systemctl start systemd-timesyncd.service

# Configurar Gsconnect no firewall
sudo firewall-cmd --zone=public --permanent --add-port=1714-1764/tcp
sudo firewall-cmd --zone=public --permanent --add-port=1714-1764/udp
sudo systemctl restart firewalld.service

# Ajustar tema do GNOME para 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'

echo "Instalação e configurações concluídas!"


