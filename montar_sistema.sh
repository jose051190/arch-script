#!/bin/bash

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute como root"
  exit 1
fi

# Listar os discos disponíveis
echo "Discos disponíveis:"
lsblk -d -o NAME,SIZE,MODEL | grep -vE "loop|sr0|zram" | awk 'NR>1 {print NR-1 ") /dev/" $1 " - " $2 " - " $3}'

# Pedir para o usuário escolher a partição raiz
echo "Digite o número da partição raiz (e.g., 1): "
read num_particao_raiz
PARTICAO_RAIZ=$(lsblk -d -o NAME | grep -vE "loop|sr0|zram" | awk -v n="$num_particao_raiz" 'NR==n+1 {print "/dev/" $1}')

# Verificar se a partição raiz é válida
if [ ! -b "$PARTICAO_RAIZ" ]; then
    echo "Partição raiz inválida: $PARTICAO_RAIZ"
    exit 1
fi

# Pedir para o usuário escolher a partição de boot
echo "Digite o número da partição de boot (e.g., 2): "
read num_particao_boot
PARTICAO_BOOT=$(lsblk -d -o NAME | grep -vE "loop|sr0|zram" | awk -v n="$num_particao_boot" 'NR==n+1 {print "/dev/" $1}')

# Verificar se a partição de boot é válida
if [ ! -b "$PARTICAO_BOOT" ]; then
    echo "Partição de boot inválida: $PARTICAO_BOOT"
    exit 1
fi

# Montar a partição raiz
echo "Montando a partição raiz em /mnt..."
mount "$PARTICAO_RAIZ" /mnt
if [ $? -ne 0 ]; then
  echo "Erro ao montar a partição raiz em /mnt"
  exit 1
fi

# Desmontar a partição raiz
echo "Desmontando a partição raiz de /mnt..."
umount /mnt
if [ $? -ne 0 ]; then
  echo "Erro ao desmontar a partição raiz de /mnt"
  exit 1
fi

# Montar os subvolumes Btrfs
echo "Montando o subvolume @root em /mnt..."
mount -o defaults,noatime,compress=zstd,subvol=@root "$PARTICAO_RAIZ" /mnt
if [ $? -ne 0 ]; then
  echo "Erro ao montar o subvolume @root"
  exit 1
fi

echo "Montando o subvolume @home em /mnt/home..."
mount -o defaults,noatime,compress=zstd,subvol=@home "$PARTICAO_RAIZ" /mnt/home
if [ $? -ne 0 ]; then
  echo "Erro ao montar o subvolume @home"
  exit 1
fi

# Montar a partição de boot
echo "Montando a partição de boot em /mnt/boot/efi..."
mount "$PARTICAO_BOOT" /mnt/boot/efi
if [ $? -ne 0 ]; then
  echo "Erro ao montar a partição de boot em /mnt/boot/efi"
  exit 1
fi

# Exibir estrutura de diretórios
echo "Estrutura de diretórios montada:"
lsblk

echo "Montagem concluída com sucesso!"

