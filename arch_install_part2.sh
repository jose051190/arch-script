#!/bin/bash

# Configurar o sistema
ln -sf /usr/share/zoneinfo/America/Fortaleza /etc/localtime
hwclock --systohc
sed -i 's/^#pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" >> /etc/locale.conf
echo "KEYMAP=br-abnt2" >> /etc/vconsole.conf

# Configuração de rede
echo "arch" > /etc/hostname
cat <<EOL > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    arch.localdomain arch
EOL

# Initramfs, senha do root, Grub e drivers
mkinitcpio -P
echo "Defina a senha do root:"
passwd

# Habilitar multilib e outras configurações do pacman
sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
pacman -Syy
pacman -S grub efibootmgr dialog os-prober ntfs-3g mtools dosfstools linux-headers bluez bluez-utils bluez-plugins git xdg-utils xdg-user-dirs wget curl pipewire lib32-pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber alsa-utils alsa-firmware alsa-tools sof-firmware
systemctl enable --now bluetooth.service
systemctl enable NetworkManager
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Configurar drivers da NVIDIA
cat <<EOL > /etc/modprobe.d/nvidia.conf
options nvidia_drm modeset=1 nvidia_drm fbdev=1
EOL
sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
mkinitcpio -P
pacman -S nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader egl-wayland opencl-nvidia lib32-opencl-nvidia libvdpau-va-gl libvdpau libva-nvidia-driver
systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service

# Usuário e senha
useradd -mG wheel jose
echo "Defina a senha do usuário jose:"
passwd jose
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# # Instalar yay
# cd /tmp/
# git clone https://aur.archlinux.org/yay.git
# cd yay
# makepkg -si

# Finalizar instalação
exit
