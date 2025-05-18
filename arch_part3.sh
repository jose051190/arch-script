#!/bin/bash

-------------------------------------

FUNÇÃO PARA VERIFICAR COMANDOS

-------------------------------------

check_command() { if [ $? -ne 0 ]; then echo "Erro ao executar: $1" exit 1 fi }

-------------------------------------

DEFINIR A PARTIÇÃO RAIZ

-------------------------------------

echo "Partições disponíveis:" lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,UUID,PARTUUID

read -p "Digite o caminho da partição raiz (ex: /dev/sda2): " ROOT_PARTITION PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_PARTITION")

if [ -z "$PARTUUID" ]; then echo "Não foi possível obter o PARTUUID. Verifique se o dispositivo está correto." exit 1 fi

-------------------------------------

INSTALAÇÃO DE PACOTES ESSENCIAIS

-------------------------------------

PACOTES_ESSENCIAIS=( wl-clipboard npm fwupd fzf syncthing ttf-nerd-fonts-symbols inter-font ttf-jetbrains-mono plymouth neovim rclone fastfetch htop ncdu virt-manager qemu-full ebtables iptables-nft dnsmasq edk2-ovmf spice-vdagent firewalld chromium flatpak zram-generator cryfs pacman-contrib pacutils expac less ksystemlog rsync sshfs go docker docker-compose toolbox cronie )

sudo pacman -S --needed "${PACOTES_ESSENCIAIS[@]}" check_command "Instalação dos pacotes essenciais"

-------------------------------------

CONFIGURAÇÃO DO PLYMOUTH COM SYSTEMD-BOOT

-------------------------------------

echo "Adicionando entrada do Plymouth ao systemd-boot" sudo sed -i "/^options/ s|$| splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0 root=PARTUUID=$PARTUUID|" /boot/loader/entries/arch.conf check_command "Configuração do systemd-boot com Plymouth"

Adicionar plymouth ao vetor HOOKS em mkinitcpio.conf após base e udev

sudo sed -i '/^HOOKS=/ s//\1 plymouth/' /etc/mkinitcpio.conf check_command "Inserção do plymouth no HOOKS"

Atualizar mkinitcpio

sudo mkinitcpio -P check_command "Atualização do mkinitcpio"

-------------------------------------

SERVIÇOS

-------------------------------------

Ativar e iniciar libvirtd

sudo systemctl enable --now libvirtd.service check_command "libvirtd"

Ativar e iniciar firewalld

sudo systemctl enable --now firewalld.service check_command "firewalld"

Ativar e iniciar syncthing para o usuário atual

sudo systemctl enable syncthing@$USER.service check_command "syncthing"

Ativar e iniciar cronie

sudo systemctl enable --now cronie.service check_command "cronie"

Ativar serviços do Docker

sudo systemctl enable docker.socket sudo systemctl enable docker.service

-------------------------------------

INSTALAÇÃO DO YAY (AUR HELPER)

-------------------------------------

cd /tmp/ git clone https://aur.archlinux.org/yay.git check_command "Clonando yay" cd yay makepkg -si --noconfirm check_command "Instalando yay"

-------------------------------------

CONFIGURAÇÃO DO ZRAM E SWAPFILE

-------------------------------------

Criar configuração do zram-generator

sudo bash -c 'cat > /etc/systemd/zram-generator.conf <<EOF [zram0] zram-size = ram compression-algorithm = zstd EOF'

Criar arquivo de swapfile

sudo touch /swapfile sudo chattr +C /swapfile sudo fallocate -l 1G /swapfile sudo chmod 600 /swapfile sudo mkswap /swapfile sudo swapon /swapfile

Recarregar systemd

sudo systemctl daemon-reexec

Ajustar parâmetros sysctl para zram

sudo bash -c 'cat > /etc/sysctl.d/99-vm-zram-parameters.conf <<EOF vm.swappiness = 180 vm.watermark_boost_factor = 0 vm.watermark_scale_factor = 125 vm.page-cluster = 0 EOF'

sudo sysctl --system

-------------------------------------

AJUSTES FINAIS

-------------------------------------

Sincronizar horário

sudo systemctl enable systemd-timesyncd.service sudo systemctl start systemd-timesyncd.service

Adicionar usuário aos grupos docker e libvirt

sudo usermod -aG docker $USER sudo usermod -aG libvirt $USER

Perguntar sobre reinicialização

read -n 1 -p "Instalação concluída. Deseja reiniciar o sistema agora? (s/n): " resposta

echo "" if [[ "$resposta" =~ ^[sS]$ ]]; then echo "Reiniciando o sistema..." sudo reboot else echo "Reinicialização cancelada. Reinicie manualmente para aplicar as alterações." fi

