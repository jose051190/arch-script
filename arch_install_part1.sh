#!/bin/bash

# Ajustar teclado e idioma
#loadkeys br-abnt2
echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
export LANG=pt_BR.UTF-8

# Atualizar o relógio do sistema
timedatectl set-ntp true

# Listar os discos disponíveis
fdisk -l | grep "Disk /dev/" | awk '{print $2}' | cut -d: -f1 | nl -n ln -w 2 -s ') '

# Pedir para o usuário selecionar os discos para particionar
echo "Digite o número dos discos que deseja particionar, separados por espaço (e.g., 1 2 3 ...): "
read nums_discos
discos=($(fdisk -l | grep "Disk /dev/" | awk '{print $2}' | cut -d: -f1 | sed -n "${nums_discos// /p};${nums_discos// /p}p"))

# Particionar os discos selecionados
for disco in "${discos[@]}"; do
    echo "Deseja particionar o disco $disco manualmente? (s/n): "
    read particionar_manualmente
    if [ "$particionar_manualmente" == "s" ]; then
        echo "Particione o disco $disco usando cfdisk. Depois de particionado, pressione qualquer tecla para continuar..."
        cfdisk $disco
        read -n 1 -s
    fi
done

# Listar as partições disponíveis
lsblk

# Pedir para o usuário informar as partições
echo "Digite a partição de boot (e.g., ${disco}1): "
read particao_boot
echo "Digite a partição raiz (e.g., ${disco}2): "
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