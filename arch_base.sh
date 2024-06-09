#!/bin/bash

# Função para configurar o Pacman
function configure_pacman {
    sed -i 's/#Color/Color/' /etc/pacman.conf
    sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
    sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
    sed -i 's/#MiscOptions/ILoveCandy\n&/' /etc/pacman.conf
}

# Ajustar teclado e idioma
echo "Escolha o layout de teclado (ex: br-abnt2, us, etc.):"
read KEYMAP
loadkeys $KEYMAP

echo "Escolha o idioma (ex: pt_BR.UTF-8, en_US.UTF-8, etc.):"
read LOCALE
echo "$LOCALE UTF-8" > /etc/locale.gen
locale-gen
export LANG=$LOCALE

# Conectar à internet
iwctl
echo "Pressione Enter após conectar à rede com iwctl..."
read -p ""

# Atualizar o sistema de pacotes
pacman-key --init
pacman-key --populate
pacman -Syy

configure_pacman

# Atualizar o relógio do sistema
timedatectl set-ntp true

# Escolher disco
lsblk
echo "Escolha o disco para instalação (ex: /dev/sda):"
read DISK

# Particionamento do disco
echo "Abrindo cfdisk para particionamento do disco $DISK..."
cfdisk $DISK

# Formatar as partições
lsblk
echo "Escolha a partição de boot:"
read PARTITION_BOOT
echo "Escolha a partição swap (opcional, deixe em branco se não tiver):"
read PARTITION_SWAP
echo "Escolha a partição raiz:"
read PARTITION_ROOT
echo "Escolha a partição home (opcional, deixe em branco se não tiver):"
read PARTITION_HOME

echo "Formatando as partições..."
mkfs.fat -F32 /dev/$PARTITION_BOOT
if [ -n "$PARTITION_SWAP" ]; then
    mkswap /dev/$PARTITION_SWAP
    swapon /dev/$PARTITION_SWAP
fi
mkfs.ext4 /dev/$PARTITION_ROOT
if [ -n "$PARTITION_HOME" ]; then
    mkfs.ext4 /dev/$PARTITION_HOME
fi

# Montar os sistemas de arquivos
echo "Montando os sistemas de arquivos..."
mount /dev/$PARTITION_ROOT /mnt
mkdir /mnt/boot
mount /dev/$PARTITION_BOOT /mnt/boot
if [ -n "$PARTITION_HOME" ]; then
    mkdir /mnt/home
    mount /dev/$PARTITION_HOME /mnt/home
fi

# Instalar os pacotes essenciais
echo "Instalando os pacotes essenciais..."
pacstrap /mnt base linux linux-firmware base-devel networkmanager network-manager-applet

# Configurar o sistema
echo "Configurando o sistema..."
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash <<EOF

# Fuso horário e localização
echo "Escolha o fuso horário (ex: America/Sao_Paulo, Europe/London, etc.):"
read TIMEZONE
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
sed -i 's/#$LOCALE/$LOCALE/' /etc/locale.gen
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

sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Habilitar serviços
systemctl enable NetworkManager

EOF

# Sair do chroot e finalizar
echo "Saindo do chroot e finalizando..."
umount -R /mnt
echo "Instalação básica concluída. Reinicie o sistema."
echo "Pressione Enter para reiniciar..."
read -p ""
reboot
