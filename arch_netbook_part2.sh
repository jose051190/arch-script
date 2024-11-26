#!/bin/bash

# Função para verificar o status dos comandos
check_command() {
  if [ $? -ne 0 ]; then
    echo "Erro ao executar: $1"
    exit 1
  fi
}

# Configurar o sistema
ln -sf /usr/share/zoneinfo/America/Fortaleza /etc/localtime
check_command "ln -sf /usr/share/zoneinfo/America/Fortaleza /etc/localtime"
hwclock --systohc
check_command "hwclock --systohc"

# Configurar locale
sed -i 's/^#pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/' /etc/locale.gen
check_command "sed -i 's/^#pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/' /etc/locale.gen"
locale-gen
check_command "locale-gen"
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
check_command "echo 'LANG=pt_BR.UTF-8' > /etc/locale.conf"

# Configuração de rede
echo "arch" > /etc/hostname
check_command "echo 'arch' > /etc/hostname"
cat <<EOL > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    arch.localdomain arch
EOL
check_command "criação de /etc/hosts"

# Configurar initramfs e senha do root
mkinitcpio -P
check_command "mkinitcpio -P"

echo "Defina a senha do root:"
passwd
check_command "passwd"

# Habilitar multilib e configurações do pacman
sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
check_command "sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf"
sed -i 's/^#Color/Color/' /etc/pacman.conf
check_command "sed -i 's/^#Color/Color/' /etc/pacman.conf"
sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
check_command "sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf"
sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
check_command "sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf"
grep -q '^ParallelDownloads = 5' /etc/pacman.conf && sed -i '/^ParallelDownloads = 5/a ILoveCandy' /etc/pacman.conf || echo -e '\nParallelDownloads = 5\nILoveCandy' >> /etc/pacman.conf
check_command "adicionar ILoveCandy"
pacman -Syu
check_command "pacman -Syu"

# Instalar pacotes essenciais
pacman -S --needed grub dialog ntfs-3g mtools dosfstools linux-headers git xdg-utils xdg-user-dirs wget curl gst-plugins-good pipewire lib32-pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber sof-firmware
check_command "pacman -S pacotes essenciais"

# Instalar pacotes adicionais
echo "Instalando pacotes adicionais..."
pacman -S --needed chromium ristretto mpv vlc galculator xarchive clipit leafpad
check_command "pacman -S pacotes adicionais"

# Instalar pacotes do LXDE
echo "Instalando pacotes do LXDE..."
pacman -S --needed lxde-common lxsession openbox pcmanfm lxappearance lxterminal lxpanel xarchiver
check_command "pacman -S pacotes do LXDE"

# Instalar LXDM (gerenciador de login)
echo "Instalando o LXDM..."
pacman -S --needed lxdm
check_command "pacman -S lxdm"

# Habilitar LXDM para iniciar automaticamente
systemctl enable lxdm
check_command "systemctl enable lxdm"

# Habilitar NetworkManager
systemctl enable NetworkManager
check_command "systemctl enable NetworkManager"

# Configuração de drivers Intel
echo "Detectando o tipo de GPU Intel..."
echo "Você está usando um hardware Intel moderno (Broadwell ou mais recente)? [s/n]"
read intel_moderno

if [ "$intel_moderno" == "s" ]; then
    echo "Instalando drivers para GPUs Intel modernas..."
    pacman -S --needed mesa vulkan-intel lib32-mesa lib32-vulkan-intel intel-media-driver xorg-server
    check_command "pacman -S drivers Intel modernos"
else
    echo "Instalando drivers para GPUs Intel antigas..."
    pacman -S --needed mesa lib32-mesa xf86-video-intel xorg-server
    check_command "pacman -S drivers Intel antigos"
fi

# Criar usuário
useradd -mG wheel jose
check_command "useradd -mG wheel jose"
echo "Defina a senha do usuário jose:"
passwd jose
check_command "passwd jose"

# Configurar GRUB para BIOS
grub-install --target=i386-pc /dev/sda
check_command "grub-install --target=i386-pc /dev/sda"
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
check_command "sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub"

# Atualizar o GRUB
grub-mkconfig -o /boot/grub/grub.cfg
check_command "grub-mkconfig -o /boot/grub/grub.cfg"

# Finalizar instalação
echo "Configuração concluída! Saia do chroot e reinicie o sistema."
exit
