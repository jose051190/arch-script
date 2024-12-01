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

# Configurar initramfs
mkinitcpio -P
check_command "mkinitcpio -P"

# Habilitar multilib e configurações do pacman
sed -i '/^multilib/,/^Include/ s/^#//' /etc/pacman.conf
check_command "sed -i '/^multilib/,/^Include/ s/^#//' /etc/pacman.conf"
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

# Instalar pacotes adicionais
echo "Instalando pacotes adicionais..."
pacman -S --needed chromium ristretto mpv vlc galculator leafpad
check_command "pacman -S pacotes adicionais"

# Instalar pacotes do Openbox
echo "Instalando pacotes do Openbox..."
pacman -S --needed openbox tint2 obconf obmenu lxappearance lxappearance-obconf pcmanfm xarchiver
check_command "pacman -S pacotes do Openbox"

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

# Configurar Openbox com startx
echo "Configurando Openbox para iniciar com startx..."
echo "exec openbox-session" > /home/jose/.xinitrc
check_command "echo 'exec openbox-session' > /home/jose/.xinitrc"
chown jose:jose /home/jose/.xinitrc
check_command "chown jose:jose /home/jose/.xinitrc"

# Criar usuário
useradd -mG wheel jose
check_command "useradd -mG wheel jose"
echo "Defina a senha do usuário jose:"
passwd jose
check_command "passwd jose"

# Finalizar configuração
echo "Configuração concluída! O sistema está pronto para uso."
exit