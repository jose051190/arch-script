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
echo "Digite o número do disco que deseja particionar: "
read num_disco

# Obter o disco selecionado
disco=$(lsblk -d -o NAME | grep -vE "loop|sr0|zram" | awk -v n="$num_disco" 'NR==n+1 {print $1}')
if [ -z "$disco" ]; then
  echo "Número de disco inválido: $num_disco"
  exit 1
fi
disco="/dev/$disco"

# Particionar o disco
echo "Deseja particionar o disco $disco manualmente? (s/n): "
read particionar_manualmente
if [ "$particionar_manualmente" == "s" ]; then
  echo "Particione o disco $disco usando cfdisk. Depois de particionado, pressione qualquer tecla para continuar..."
  cfdisk $disco
  read -n 1 -s
fi

# Listar as partições disponíveis
echo "Partições disponíveis:"
lsblk

# Pedir para o usuário informar a partição raiz
echo "Digite a partição raiz (e.g., /dev/sda1): "
read particao_raiz

# Verificar se a partição existe
if [ ! -b "$particao_raiz" ]; then
    echo "Partição raiz inválida: $particao_raiz"
    exit 1
fi

# Formatar a partição raiz
echo "Formatando partição raiz com Ext4..."
mkfs.ext4 $particao_raiz
if [ $? -ne 0 ]; then
  echo "Erro ao formatar a partição raiz"
  exit 1
fi

# Montar a partição raiz
echo "Montando a partição raiz..."
mount $particao_raiz /mnt
if [ $? -ne 0 ]; then
  echo "Erro ao montar a partição raiz"
  exit 1
fi

# Instalar os pacotes essenciais
echo "Instalando pacotes essenciais..."
pacstrap -K /mnt base linux linux-firmware nano base-devel intel-ucode networkmanager network-manager-applet bash-completion linux-headers
if [ $? -ne 0 ]; then
  echo "Erro ao instalar pacotes essenciais"
  exit 1
fi

# Copiar scripts para o ambiente chroot
echo "Copiando scripts para o ambiente chroot..."
cp arch_netbook_part2.sh /mnt/
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
arch-chroot /mnt /bin/bash /arch_netbook_part2.sh
if [ $? -ne 0 ]; then
  echo "Erro ao entrar no ambiente chroot"
  exit 1
fi

echo "Instalação inicial concluída com sucesso!"

