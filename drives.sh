#!/bin/bash

# Função para instalar drivers de vídeo NVIDIA
function install_nvidia() {
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
    pacman -S --noconfirm $inlst
    echo -e 'options nvidia_drm modeset=1 nvidia_drm fbdev=1 ' | sudo tee -a /etc/modprobe.d/nvidia.conf
    sudo sed -i '/^MODULES=(/ s/)$/ nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
}

# Função para instalar e configurar o Bluetooth
function install_bluetooth() {
    local -r inlst="
        bluez
        bluez-plugins
        bluez-utils
    "
    pacman -S --noconfirm $inlst
    sudo systemctl enable bluetooth
}

# Verificar se o usuário é root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

# Instalar drivers da NVIDIA
install_nvidia

# Instalar e configurar o Bluetooth
install_bluetooth

echo "Drivers da NVIDIA e Bluetooth instalados com sucesso."
