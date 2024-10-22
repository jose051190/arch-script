#!/bin/bash

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute como root"
  exit 1
fi

# Ajustar teclado e idioma
echo "Ajustando o idioma para pt_BR.UTF-8..."
if ! grep -q "pt_BR.UTF-8 UTF-8" /etc/locale.gen; then
  echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen
fi
locale-gen
export LANG=pt_BR.UTF-8

# Atualizar o relógio do sistema
echo "Atualizando o relógio do sistema..."
timedatectl set-ntp true

# Listar os discos disponíveis
echo "Discos disponíveis:"
lsblk -d -o NAME,SIZE,MODEL | grep -vE "loop|sr0|zram" | awk 'NR>1 {print NR-1 ") " $0}'

# Pedir para o usuário selecionar os discos para particionar
echo "Digite o número dos discos que deseja particionar, separados por espaço (e.g., 1 2 3 ...): "
read -a nums_discos

# Obter os discos selecionados
discos=()
for num in "${nums_discos[@]}"; do
    disco=$(lsblk -d -o NAME | grep -vE "loop|sr0|zram" | awk -v n="$num" 'NR==n+1 {print $1}')
    if [ -z "$disco" ]; then
        echo "Número de disco inválido: $num"
        exit 1
    fi
    discos+=("/dev/$disco")
done

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
echo "Partições disponíveis:"
lsblk

# Pedir para o usuário informar as partições
echo "Digite a partição de boot (e.g., /dev/sda1): "
read particao_boot
echo "Digite a partição raiz (e.g., /dev/sda2): "
read particao_raiz

# Verificar se as partições existem
if [ ! -b "$particao_boot" ]; then
    echo "Partição de boot inválida: $particao_boot"
    exit 1
fi
if [ ! -b "$particao_raiz" ]; then
    echo "Partição raiz inválida: $particao_raiz"
    exit 1
fi

# Formatar as partições
echo "Formatando partição de boot..."
mkfs.fat -F32 $particao_boot
if [ $? -ne 0 ]; then
  echo "Erro ao formatar a partição de boot"
  exit 1
fi

# Limpar a partição raiz antes de formatar
echo "Limpando possíveis sistemas de arquivos antigos da partição raiz..."
wipefs -a $particao_raiz
if [ $? -ne 0 ]; then
  echo "Erro ao limpar a partição raiz"
  exit 1
fi

echo "Formatando partição raiz com Btrfs..."
mkfs.btrfs $particao_raiz
if [ $? -ne 0 ]; then
  echo "Erro ao formatar a partição raiz"
  exit 1
fi

# Montar a partição raiz e criar subvolumes
echo "Montando a partição raiz e criando subvolumes..."
mount $particao_raiz /mnt
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
#btrfs subvolume create /mnt/@snapshots
umount /mnt

# Montar os subvolumes com compressão
echo "Montando subvolumes com compressão..."
mount -o defaults,noatime,compress=zstd,subvol=@root $particao_raiz /mnt
mkdir -p /mnt/{boot/efi,home}
mount -o defaults,noatime,compress=zstd,subvol=@home $particao_raiz /mnt/home
#mount -o #defaults,noatime,compress=zstd,subvol=@snapshots $particao_raiz /mnt/.snapshots

# Montar a partição de boot
echo "Montando a partição de boot..."
mount $particao_boot /mnt/boot/efi

# Instalar os pacotes essenciais
echo "Instalando pacotes essenciais..."
pacstrap -K /mnt base linux linux-firmware nano base-devel intel-ucode networkmanager network-manager-applet bash-completion linux-headers
if [ $? -ne 0 ]; then
  echo "Erro ao instalar pacotes essenciais"
  exit 1
fi

# Copiar scripts para o ambiente chroot
echo "Copiando scripts para o ambiente chroot..."
cp arch_install_amd_part2.sh arch_install_amd_part3.sh /mnt/
if [ $? -ne 0 ]; then
  echo "Erro ao copiar scripts para o ambiente chroot"
  exit 1
fi

# Gerar o fstab
echo "Gerando o fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
if [ $? -ne 0 ]; then
  echo "Erro ao gerar o fstab"
  exit 1
fi

# Entrar no ambiente chroot e executar a próxima parte da instalação
echo "Entrando no ambiente chroot..."
arch-chroot /mnt /bin/bash /arch_install_amd_part2.sh
if [ $? -ne 0 ]; then
  echo "Erro ao entrar no ambiente chroot"
  exit 1
fi

echo "Instalação inicial concluída com sucesso!"

