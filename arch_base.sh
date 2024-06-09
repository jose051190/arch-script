#!/bin/bash

# Função para configurar o Pacman
function configure_pacman {
    sed -i 's/#Color/Color/; s/#VerbosePkgLists/VerbosePkgLists/; s/#ParallelDownloads = 5/ParallelDownloads = 5/; s/#MiscOptions/ILoveCandy\n&/' /etc/pacman.conf
}

# Função para listar opções de teclado
function list_keyboard_options {
    echo "Opções de layout de teclado disponíveis:"
    localectl list-keymaps
}

# Função para listar opções de idioma
function list_language_options {
    echo "Opções de idioma disponíveis:"
    localectl list-locales
}

# Ajustar teclado e idioma
echo "Configuração de teclado e idioma:"

list_keyboard_options
read -p "Digite o layout de teclado desejado: " KEYMAP
loadkeys $KEYMAP

list_language_options
read -p "Digite o idioma desejado: " LOCALE
echo "$LOCALE UTF-8" > /etc/locale.gen
locale-gen
export LANG=$LOCALE

# Atualizar o sistema de pacotes
echo "Atualizando sistema de pacotes..."
pacman-key --init
pacman-key --populate
pacman -Sy

configure_pacman

# Atualizar o relógio do sistema
timedatectl set-ntp true

# Escolher disco
echo "Escolha o disco para instalação:"
lsblk -o NAME,SIZE,TYPE,FSTYPE | grep disk
read -p "Digite o disco para instalação (ex: /dev/sda): " DISK

# Particionar o disco
echo "Particionamento do disco $DISK..."
cfdisk $DISK

# Formatar as partições
echo "Formatando as partições..."
lsblk -o NAME,SIZE,TYPE,FSTYPE | grep -e "^$DISK" | grep -v -e "disk"
read -p "Digite a partição de boot: " PARTITION_BOOT
read -p "Digite a partição swap (opcional, deixe em branco se não tiver): " PARTITION_SWAP
read -p "Digite a partição raiz: " PARTITION_ROOT
read -p "Digite a partição home (opcional, deixe em branco se não tiver): " PARTITION_HOME

mkfs.fat -F32 /dev/$PARTITION_BOOT
[ -n "$PARTITION_SWAP" ] && { mkswap /dev/$PARTITION_SWAP; swapon /dev/$PARTITION_SWAP; }
mkfs.ext4 /dev/$PARTITION_ROOT
[ -n "$PARTITION_HOME" ] && mkfs.ext4 /dev/$PARTITION_HOME

# Montar os sistemas de arquivos
echo "Montando os sistemas de arquivos..."
mount /dev/$PARTITION_ROOT /mnt
mkdir /mnt/boot
mount /dev/$PARTITION_BOOT /mnt/boot
[ -n "$PARTITION_HOME" ] && { mkdir /mnt/home; mount /dev/$PARTITION_HOME /mnt/home; }

# Instalar os pacotes essenciais
echo "Instalando os pacotes essenciais..."
pacstrap /mnt base linux linux-firmware base-devel networkmanager network-manager-applet git

# Configurar o sistema
echo "Configurando o sistema..."
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
