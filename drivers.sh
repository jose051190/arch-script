#!/bin/bash

# Função para verificar o status dos comandos
check_command() {
  if [ $? -ne 0 ]; then
    echo "Erro ao executar: $1"
    exit 1
  fi
}

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
check_command "pacman -Syy"

# Adicionar parâmetros da NVIDIA ao GRUB
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& nvidia-drm.modeset=1/' /etc/default/grub
check_command "sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*/& nvidia-drm.modeset=1/' /etc/default/grub"
grub-mkconfig -o /boot/grub/grub.cfg
check_command "grub-mkconfig -o /boot/grub/grub.cfg"

# Configurar drivers da NVIDIA
pacman -S --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader egl-wayland opencl-nvidia lib32-opencl-nvidia libvdpau-va-gl libvdpau libva-nvidia-driver
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

# Finalizar instalação
exit

