#!/bin/bash
set -e  # Encerra o script se algum comando retornar erro

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute como root"
  exit 1
fi

# Listar os discos disponíveis
echo "Discos disponíveis:"
lsblk -p -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT -e 7

# Pedir para o usuário escolher a partição raiz
echo "Digite o caminho completo da partição raiz (e.g., /dev/sda1): "
read PARTICAO_RAIZ

# Verificar se a partição raiz é válida
if [ ! -b "$PARTICAO_RAIZ" ]; then
  echo "Partição raiz inválida: $PARTICAO_RAIZ"
  exit 1
fi

# Pedir para o usuário escolher a partição de boot
echo "Digite o caminho completo da partição de boot (e.g., /dev/sda2): "
read PARTICAO_BOOT

# Verificar se a partição de boot é válida
if [ ! -b "$PARTICAO_BOOT" ]; then
  echo "Partição de boot inválida: $PARTICAO_BOOT"
  exit 1
fi

# Montar o subvolume raiz
echo "Montando o subvolume @root em /mnt..."
mount -o defaults,noatime,compress=zstd,space_cache=v2,subvol=@root "$PARTICAO_RAIZ" /mnt

# Montar o subvolume home
echo "Montando o subvolume @home em /mnt/home..."
mount -o defaults,noatime,compress=zstd,space_cache=v2,subvol=@home "$PARTICAO_RAIZ" /mnt/home

# Montar a partição de boot
echo "Montando a partição de boot em /mnt/boot/efi..."
mount "$PARTICAO_BOOT" /mnt/boot/efi

# Exibir estrutura de diretórios
echo "Estrutura de diretórios montada:"
findmnt /mnt
echo "Montagem concluída com sucesso!"