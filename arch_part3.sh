#!/bin/bash

#-------------------------------------
# FUNÇÃO PARA VERIFICAR COMANDOS
#-------------------------------------
check_command() { 
    if [ $? -ne 0 ]; then 
        echo "Erro ao executar: $1" 
        exit 1 
    fi
}

#-------------------------------------
# INSTALAÇÃO DE PACOTES ESSENCIAIS
#-------------------------------------
PACOTES_ESSENCIAIS=(wl-clipboard yazi fd ffmpeg unzip unrar 7zip jq poppler zoxide imagemagick npm fwupd fzf ttf-nerd-fonts-symbols inter-font noto-fonts ttf-jetbrains-mono-nerd plymouth neovim rclone fastfetch htop btop ncdu virt-manager qemu-full dnsmasq edk2-ovmf spice-vdagent firewalld pacman-contrib pacutils expac less ksystemlog rsync sshfs go docker docker-compose cronie)

sudo pacman -S --needed "${PACOTES_ESSENCIAIS[@]}"
check_command "Instalação dos pacotes essenciais"

#-------------------------------------
# CONFIGURAÇÃO DO PLYMOUTH COM GRUB
#-------------------------------------
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&splash rd.udev.log_priority=3 vt.global_cursor_default=0 /' /etc/default/grub
check_command "Modificação do GRUB_CMDLINE_LINUX_DEFAULT"

# Atualizar GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg
check_command "Atualização do GRUB"

# Adicionar plymouth ao vetor HOOKS em mkinitcpio.conf após base e udev
sudo sed -i '/^HOOKS=/ s/\(base udev\)/\1 plymouth/' /etc/mkinitcpio.conf
check_command "Adição do plymouth aos HOOKS"

# Atualizar mkinitcpio
sudo mkinitcpio -p linux
check_command "Atualização do mkinitcpio"

#-------------------------------------
# SERVIÇOS
#-------------------------------------
# Ativar e iniciar libvirtd
sudo systemctl enable --now libvirtd.service 
check_command "Ativação do libvirtd"

# Ativar e iniciar firewalld
sudo systemctl enable --now firewalld.service 
check_command "Ativação do firewalld"

# Ativar e iniciar cronie
sudo systemctl enable --now cronie.service 
check_command "Ativação do cronie"

# Ativar serviços do Docker
sudo systemctl enable --now docker.socket
sudo systemctl enable --now docker.service
check_command "Ativação do docker"

#-------------------------------------
# INSTALAÇÃO DO YAY (AUR HELPER)
#-------------------------------------
cd /tmp/ 
git clone https://aur.archlinux.org/yay.git 
check_command "Clonando yay" 
cd yay 
makepkg -si --noconfirm 
check_command "Instalando yay"

#-------------------------------------
# CONFIGURAÇÃO DO ZRAM E SWAPFILE
#-------------------------------------
# Criar configuração do zram-generator
sudo bash -c 'cat > /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = ram
compression-algorithm = zstd
EOF'

# Criar arquivo de swapfile
sudo touch /swapfile 
sudo chattr +C /swapfile 
sudo fallocate -l 1G /swapfile 
sudo chmod 600 /swapfile 
sudo mkswap /swapfile 
sudo swapon /swapfile

# Recarregar systemd
sudo systemctl daemon-reexec

# Ajustar parâmetros sysctl para zram
sudo bash -c 'cat > /etc/sysctl.d/99-vm-zram-parameters.conf <<EOF
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF'

sudo sysctl --system

#-------------------------------------
# AJUSTES FINAIS
#-------------------------------------
# Sincronizar horário
sudo systemctl enable --now systemd-timesyncd.service

# Adicionar usuário aos grupos docker e libvirt
sudo usermod -aG docker $USER 
sudo usermod -aG libvirt $USER

# Perguntar sobre reinicialização
read -n 1 -p "Instalação concluída. Deseja reiniciar o sistema agora? (s/n): " resposta

echo ""
if [[ "$resposta" =~ ^[sS]$ ]]; then 
    echo "Reiniciando o sistema..." 
    sudo reboot 
else 
    echo "Reinicialização cancelada. Reinicie manualmente para aplicar as alterações." 
fi
