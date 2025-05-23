#!/bin/bash

# ------------------------------
# Variáveis personalizáveis
# ------------------------------
USERNAME="jose"
HOSTNAME="arch"
TIMEZONE="America/Fortaleza"
LOCALE="pt_BR.UTF-8"

# Pacotes essenciais (sem drivers)
ESSENTIAL_PACKAGES=(
  bluez bluez-utils bluez-plugins
  git wget curl dialog
  xdg-utils xdg-user-dirs
  ntfs-3g mtools dosfstools
  gst-plugins-good
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
  sof-firmware
  btrfs-progs
)

# Pacotes de drivers AMD
AMD_DRIVER_PACKAGES=(
  mesa lib32-mesa
  vulkan-radeon lib32-vulkan-radeon
  libva-mesa-driver lib32-libva-mesa-driver
  mesa-vdpau lib32-mesa-vdpau
  vulkan-icd-loader lib32-vulkan-icd-loader
  vulkan-mesa-layers
)

# ------------------------------
# Cores para terminal
# ------------------------------
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# ------------------------------
# Função para verificar o status dos comandos
# ------------------------------
check_command() {
  if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao executar: $1${RESET}"
    exit 1
  else
    echo -e "${GREEN}Sucesso: $1${RESET}"
  fi
}

# ------------------------------
# Configurar fuso horário
# ------------------------------
echo -e "${YELLOW}>> Configurando o fuso horário...${RESET}"
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
check_command "ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime"

hwclock --systohc
check_command "hwclock --systohc"

# ------------------------------
# Configurar locale
# ------------------------------
echo -e "${YELLOW}>> Configurando locale...${RESET}"
sed -i "s/^#$LOCALE UTF-8/$LOCALE UTF-8/" /etc/locale.gen
check_command "Ativar locale $LOCALE"

locale-gen
check_command "locale-gen"

echo "LANG=$LOCALE" > /etc/locale.conf
check_command "Definir LANG=$LOCALE"

# ------------------------------
# Configurar hostname e hosts
# ------------------------------
echo -e "${YELLOW}>> Configurando hostname e hosts...${RESET}"
echo "$HOSTNAME" > /etc/hostname
check_command "Definir hostname"

cat <<EOF > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    $HOSTNAME.localdomain $HOSTNAME
EOF
check_command "Criar /etc/hosts"

# ------------------------------
# Instalar pacotes essenciais
# ------------------------------
echo -e "${YELLOW}>> Instalando pacotes essenciais...${RESET}"
pacman -S --needed --noconfirm "${ESSENTIAL_PACKAGES[@]}"
check_command "Instalação de pacotes essenciais"

# ------------------------------
# Gerar initramfs
# ------------------------------
echo -e "${YELLOW}>> Gerando initramfs...${RESET}"
mkinitcpio -P
check_command "mkinitcpio -P"

# ------------------------------
# Definir senha root
# ------------------------------
echo -e "${YELLOW}>> Defina a senha do root:${RESET}"
passwd
check_command "passwd"

# ------------------------------
# Configurar pacman.conf (multilib, cores, etc)
# ------------------------------
echo -e "${YELLOW}>> Habilitando multilib e ajustes do pacman.conf...${RESET}"
sed -i '/\[multilib\/,/Include/ s/^#//' /etc/pacman.conf
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

# Adiciona ILoveCandy só se ParallelDownloads = 5 existir
grep -q '^ParallelDownloads = 5' /etc/pacman.conf && sed -i '/^ParallelDownloads = 5/a ILoveCandy' /etc/pacman.conf
check_command "Configurações do pacman.conf"

# ------------------------------
# Atualizar sistema
# ------------------------------
echo -e "${YELLOW}>> Atualizando sistema...${RESET}"
pacman -Syu --noconfirm
check_command "pacman -Syu"

# ------------------------------
# Instalar pacotes essenciais
# ------------------------------
echo -e "${YELLOW}>> Instalando pacotes essenciais...${RESET}"
pacman -S --needed --noconfirm "${ESSENTIAL_PACKAGES[@]}"
check_command "Instalação de pacotes essenciais"

# ------------------------------
# Habilitar serviços bluetooth e NetworkManager
# ------------------------------
echo -e "${YELLOW}>> Habilitando serviços bluetooth e NetworkManager...${RESET}"
systemctl enable bluetooth.service
check_command "bluetooth.service"

systemctl enable NetworkManager
check_command "NetworkManager"

# ------------------------------
# Instalar systemd-boot e configurar bootloader
# ------------------------------
echo -e "${YELLOW}>> Instalando systemd-boot...${RESET}"
bootctl install
check_command "bootctl install"

echo -e "${YELLOW}>> Criando entrada do systemd-boot...${RESET}"

# -------------------------------------
# DEFINIR A PARTIÇÃO RAIZ
# -------------------------------------

# Listar os discos e partições montadas para ajudar o usuário a identificar a partição raiz
echo "Partições disponíveis:"
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,UUID,PARTUUID

# Solicitar ao usuário que informe o caminho da partição raiz (ex: /dev/sda2)
read -p "Digite o caminho da partição raiz (ex: /dev/sda2): " ROOT_PARTITION

# Obter o PARTUUID da partição raiz informada
PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_PARTITION")

# Verificar se o PARTUUID foi obtido com sucesso
if [ -z "$PARTUUID" ]; then
  echo "Não foi possível obter o PARTUUID. Verifique se o dispositivo está correto."
  exit 1
fi# -------------------------------------
# DEFINIR A PARTIÇÃO RAIZ
# -------------------------------------

# Listar os discos e partições montadas para ajudar o usuário a identificar a partição raiz
echo "Partições disponíveis:"
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,UUID,PARTUUID

# Solicitar ao usuário que informe o caminho da partição raiz (ex: /dev/sda2)
read -p "Digite o caminho da partição raiz (ex: /dev/sda2): " ROOT_PARTITION

# Obter o PARTUUID da partição raiz informada
PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_PARTITION")

# Verificar se o PARTUUID foi obtido com sucesso
if [ -z "$PARTUUID" ]; then
  echo "Não foi possível obter o PARTUUID. Verifique se o dispositivo está correto."
  exit 1
fi

cat <<EOF > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=$PARTUUID rw
EOF
check_command "Criar /boot/loader/entries/arch.conf"

cat <<EOF > /boot/loader/loader.conf
default arch
timeout 3
editor no
EOF
check_command "Criar /boot/loader/loader.conf"

# ------------------------------
# Instalar drivers AMD
# ------------------------------
echo -e "${YELLOW}>> Instalando drivers AMD...${RESET}"
pacman -S --needed --noconfirm "${AMD_DRIVER_PACKAGES[@]}"
check_command "Instalação de drivers AMD"

# ------------------------------
# Criar usuário e configurar sudo
# ------------------------------
echo -e "${YELLOW}>> Criando usuário $USERNAME...${RESET}"
useradd -mG wheel $USERNAME
check_command "useradd $USERNAME"

echo -e "${YELLOW}>> Defina a senha do usuário $USERNAME:${RESET}"
passwd $USERNAME
check_command "passwd $USERNAME"

echo "$USERNAME ALL=(ALL) ALL" > /etc/sudoers.d/$USERNAME
check_command "Permissões sudo para $USERNAME"

echo -e "${GREEN}>> Instalação da Parte 2 concluída com sucesso.${RESET}"

exit
