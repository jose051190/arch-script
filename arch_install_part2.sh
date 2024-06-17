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
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf
check_command "echo 'KEYMAP=br-abnt2' > /etc/vconsole.conf"

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
pacman -Syy
check_command "pacman -Syy"
pacman -S grub efibootmgr dialog os-prober ntfs-3g mtools dosfstools linux-headers bluez bluez-utils bluez-plugins git xdg-utils xdg-user-dirs wget curl pipewire lib32-pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber alsa-utils alsa-firmware alsa-tools sof-firmware
check_command "pacman -S pacotes essenciais"

# Habilitar serviços
systemctl enable bluetooth.service
check_command "systemctl enable bluetooth.service"
systemctl start bluetooth.service
check_command "systemctl start bluetooth.service"

systemctl enable NetworkManager
check_command "systemctl enable NetworkManager"
systemctl start NetworkManager
check_command "systemctl start NetworkManager"

# Instalar e configurar GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
check_command "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB"
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
check_command "sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub"
grub-mkconfig -o /boot/grub/grub.cfg
check_command "grub-mkconfig -o /boot/grub/grub.cfg"

# Configurar drivers da NVIDIA
pacman -S nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader egl-wayland opencl-nvidia lib32-opencl-nvidia libvdpau-va-gl libvdpau libva-nvidia-driver
check_command "pacman -S pacotes NVIDIA"

# Criar arquivo de configuração do modprobe para NVIDIA
cat <<EOL > /etc/modprobe.d/nvidia.conf
options nvidia_drm modeset=1
EOL
check_command "criação de /etc/modprobe.d/nvidia.conf"

# Atualizar o initramfs
sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
check_command "sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf"
mkinitcpio -P
check_command "mkinitcpio -P"

# Habilitar serviços NVIDIA
systemctl enable nvidia-suspend.service
check_command "systemctl enable nvidia-suspend.service"
systemctl enable nvidia-hibernate.service
check_command "systemctl enable nvidia-hibernate.service"
systemctl enable nvidia-resume.service
check_command "systemctl enable nvidia-resume.service"

# Criar usuário e configurar sudo
useradd -mG wheel jose
check_command "useradd -mG wheel jose"
echo "Defina a senha do usuário jose:"
passwd jose
check_command "passwd jose"
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
check_command "sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers"

# Instalar yay
# cd /tmp/
# git clone https://aur.archlinux.org/yay.git
# cd yay
# makepkg -si
# check_command "instalação do yay"

# Finalizar instalação
exit