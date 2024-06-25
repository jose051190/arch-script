#!/bin/bash

# Função para verificar o status dos comandos
check_command() {
  if [ $? -ne 0 ]; then
    echo "Erro ao executar: $1"
    exit 1
  fi
}

# Habilitar multilib e outras configurações do pacman
sudo sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
check_command "sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf"

# Descomentar configurações no pacman.conf e adicionar ILoveCandy
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
check_command "sed -i 's/^#Color/Color/' /etc/pacman.conf"
sudo sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
check_command "sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf"
sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
check_command "sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf"
grep -q '^ParallelDownloads = 5' /etc/pacman.conf && sudo sed -i '/^ParallelDownloads = 5/a ILoveCandy' /etc/pacman.conf || echo -e '\nParallelDownloads = 5\nILoveCandy' >> /etc/pacman.conf
check_command "adicionar ILoveCandy"
sudo pacman -Syu
check_command "sudo pacman -Syy"

# Adicionar parâmetros da NVIDIA ao GRUB
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& nvidia-drm.modeset=1/' /etc/default/grub
check_command "sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*/& nvidia-drm.modeset=1/' /etc/default/grub"
sudo grub-mkconfig -o /boot/grub/grub.cfg
check_command "grub-mkconfig -o /boot/grub/grub.cfg"

# Instalar yay
cd /tmp/
git clone https://aur.archlinux.org/yay.git
check_command "git clone https://aur.archlinux.org/yay.git"
cd yay
makepkg -si --noconfirm
check_command "makepkg -si"

# Pacotes adicionais do AUR
yay -S --needed --noconfirm onlyoffice-bin visual-studio-code-bin pdfsam protonup-qt nvidia-beta-dkms nvidia-utils-beta lib32-nvidia-utils-beta opencl-nvidia-beta lib32-opencl-nvidia-beta nvidia-settings bottles dxvk-bin proton-ge-custom protontricks protonup-qt wine-installer gamescope-nvidia

# Configurar drivers da NVIDIA
sudo pacman -S --needed --noconfirm libva-nvidia-driver vulkan-icd-loader lib32-vulkan-icd-loader egl-wayland libvdpau-va-gl libvdpau
check_command "pacman -S pacotes NVIDIA"

# Criar arquivo de configuração do modprobe para NVIDIA
sudo cat <<EOL > /etc/modprobe.d/nvidia.conf
options nvidia_drm modeset=1
EOL
check_command "criação de /etc/modprobe.d/nvidia.conf"

# Atualizar o initramfs
sudo sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
check_command "sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf"
sudo mkinitcpio -P
check_command "mkinitcpio -P"

# Habilitar serviços NVIDIA
sudo systemctl enable nvidia-suspend.service
check_command "systemctl enable nvidia-suspend.service"
sudo systemctl enable nvidia-hibernate.service
check_command "systemctl enable nvidia-hibernate.service"
sudo systemctl enable nvidia-resume.service
check_command "systemctl enable nvidia-resume.service"

sudo pacman -S --needed --noconfirm efibootmgr dialog os-prober ntfs-3g mtools dosfstools linux-headers bluez bluez-utils bluez-plugins git xdg-utils wget curl
check_command "pacman -S pacotes essenciais"

# Habilitar serviços
sudo systemctl enable bluetooth.service
check_command "systemctl enable bluetooth.service"
sudo systemctl start bluetooth.service
check_command "systemctl start bluetooth.service"

# Finalizar instalação
exit

