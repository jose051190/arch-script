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

# Configurar initramfs, senha do root e instalar GRUB
mkinitcpio -P
check_command "mkinitcpio -P"
echo "Defina a senha do root:"
passwd
check_command "passwd"

# Habilitar multilib e outras configurações do pacman
sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
check_command "sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf"

# Descomentar configurações no pacman.conf e adicionar ILoveCandy
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
pacman -S --needed grub efibootmgr dialog os-prober ntfs-3g mtools dosfstools linux-headers bluez bluez-utils bluez-plugins git xdg-utils xdg-user-dirs wget curl pipewire lib32-pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber sof-firmware
check_command "pacman -S pacotes essenciais"

# Habilitar serviços
systemctl enable bluetooth.service
check_command "systemctl enable bluetooth.service"
systemctl start bluetooth.service
check_command "systemctl start bluetooth.service"

systemctl enable NetworkManager
check_command "systemctl enable NetworkManager"
check_command "systemctl start NetworkManager"

# Instalar e configurar GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
check_command "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ARCH"
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
check_command "sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub"

# Atualizar o GRUB
grub-mkconfig -o /boot/grub/grub.cfg
check_command "grub-mkconfig -o /boot/grub/grub.cfg"

# Instalar pacotes AMD
pacman -S --needed mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon lib32-vulkan-radeon  libva-mesa-driver lib32-libva-mesa-driver lib32-mesa-vdpau mesa-vdpau vulkan-icd-loader lib32-vulkan-icd-loader vulkan-mesa-layers
check_command "pacman -S pacotes AMD"

# Criar usuário
useradd -mG wheel jose
check_command "useradd -mG wheel jose"
echo "Defina a senha do usuário jose:"
passwd jose
check_command "passwd jose"

# Finalizar instalação
exit
