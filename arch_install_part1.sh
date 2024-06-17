#!/bin/bash

# Ajustar teclado e idioma
loadkeys br-abnt2
echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
export LANG=pt_BR.UTF-8

# Atualizar o relógio do sistema
timedatectl set-ntp true

# Partição dos discos
fdisk -l
lsblk
echo "Particione seus discos usando cfdisk. Depois de particionado, pressione qualquer tecla para continuar..."
cfdisk
read -n 1 -s

# Listar as partições disponíveis
lsblk

# Pedir para o usuário informar as partições
echo "Digite a partição de boot (e.g., /dev/sda1): "
read particao_boot
echo "Digite a partição raiz (e.g., /dev/sda2): "
read particao_raiz

# Formatar as partições
mkfs.fat -F32 $particao_boot
mkfs.ext4 $particao_raiz

# Montar os sistemas de arquivos
mount $particao_raiz /mnt
mkdir /mnt/boot
mount $particao_boot /mnt/boot

# Instalar os pacotes essenciais
pacstrap -K /mnt base linux linux-firmware nano dhcpcd base-devel intel-ucode networkmanager network-manager-applet bash-completion

# Copiar o script de chroot para o ambiente montado
cp arch_install_part2.sh /mnt/

# Configurar o sistema
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash /arch_install_part2.sh