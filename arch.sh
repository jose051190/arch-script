#!/bin/bash

# Função para instalar drivers de vídeo NVIDIA
function nvidia_config() {
    local -r inlst="
        nvidia-dkms
        nvidia-utils
        lib32-nvidia-utils
        nvidia-settings
        vulkan-icd-loader
        lib32-vulkan-icd-loader
        egl-wayland
        opencl-nvidia
        lib32-opencl-nvidia
        libvdpau-va-gl
        libvdpau
        libva-nvidia-driver
    "
    install_lst "${inlst}"
    exec_log "sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service" "$(eval_gettext "Enabling nvidia services")"
}

# Fuso horário e localização
echo "Escolha o fuso horário (ex: America/Sao_Paulo, Europe/London, etc.):"
read TIMEZONE
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
sed -i "s/#$LOCALE/$LOCALE/" /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Configuração de rede
echo "Digite o hostname:"
read HOSTNAME
echo "$HOSTNAME" > /etc/hostname
cat <<EOT > /etc/hosts
127.0.0.1        localhost
::1              localhost
127.0.1.1        $HOSTNAME.localdomain        $HOSTNAME
EOT

# Initramfs e senha do root
mkinitcpio -P
echo "Digite a senha do root:"
passwd

# Instalar e configurar o GRUB
echo "Escolha o tipo de boot (BIOS ou UEFI):"
read BOOT_TYPE
if [ "$BOOT_TYPE" == "BIOS" ]; then
    pacman -S --noconfirm grub
    grub-install --target=i386-pc $DISK
else
    pacman -S --noconfirm grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
fi

sed -i "s/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Configurar drivers de vídeo NVIDIA
echo "Deseja instalar os drivers de vídeo NVIDIA (y/n)?"
read INSTALL_NVIDIA
if [ "$INSTALL_NVIDIA" == "y" ]; then
    nvidia_config
fi

# Habilitar serviços
systemctl enable NetworkManager

# Sair do chroot e finalizar
echo "Saindo do chroot e finalizando..."
umount -R /mnt
echo "Instalação básica concluída. Reinicie o sistema."
echo "Pressione Enter para reiniciar..."
read -p ""
reboot

