#!/bin/bash

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute como root"
  exit 1
fi

# Ajustar teclado e idioma
#loadkeys br-abnt2
echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
export LANG=pt_BR.UTF-8

# Atualizar o relógio do sistema
timedatectl set-ntp true

# Listar os discos disponíveis usando lsblk
echo "Discos disponíveis:"
lsblk -d -o NAME,SIZE,MODEL | grep -vE "loop|sr0|zram" | awk 'NR>1 {print NR-1 ") " $0}'

# Pedir para o usuário selecionar os discos para particionar
echo "Digite o número dos discos que deseja particionar, separados por espaço (e.g., 1 2 3 ...): "
read -a nums_discos

# Obter os discos selecionados
discos=()
for num in "${nums_discos[@]}"; do
    disco=$(lsblk -d -o NAME | grep -vE "loop|sr0|zram" | awk -v n="$num" 'NR==n+1 {print $1}')
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
lsblk

# Pedir para o usuário informar as partições
echo "Digite a partição de boot (e.g., /dev/sda1): "
read particao_boot
echo "Digite a partição raiz (e.g., /dev/sda2): "
read particao_raiz

# Formatar as partições
echo "Formatando partição de boot..."
mkfs.fat -F32 $particao_boot
if [ $? -ne 0 ]; then
  echo "Erro ao formatar a partição de boot"
  exit 1
fi

echo "Formatando partição raiz..."
mkfs.ext4 $particao_raiz
if [ $? -ne 0 ]; then
  echo "Erro ao formatar a partição raiz"
  exit 1
fi

# Montar os sistemas de arquivos
echo "Montando a partição raiz..."
mount $particao_raiz /mnt
if [ $? -ne 0 ]; then
  echo "Erro ao montar a partição raiz"
  exit 1
fi

echo "Criando diretório /mnt/boot e montando a partição de boot..."
mkdir /mnt/boot
mount $particao_boot /mnt/boot
if [ $? -ne 0 ]; then
  echo "Erro ao montar a partição de boot"
  exit 1
fi

# Instalar os pacotes essenciais
echo "Instalando pacotes essenciais..."
pacstrap -K /mnt base linux linux-firmware nano dhcpcd base-devel intel-ucode networkmanager network-manager-applet bash-completion
if [ $? -ne 0 ]; then
  echo "Erro ao instalar pacotes essenciais"
  exit 1
fi

# Copiar o script de chroot para o ambiente montado
echo "Copiando script de chroot para o ambiente montado..."
cp arch_install_part2.sh /mnt/
if [ $? -ne 0 ]; then
  echo "Erro ao copiar script de chroot"
  exit 1
fi

# Configurar o sistema
echo "Gerando o fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
if [ $? -ne 0 ]; then
  echo "Erro ao gerar o fstab"
  exit 1
fi

echo "Entrando no ambiente chroot..."
arch-chroot /mnt /bin/bash /arch_install_part2.sh
if [ $? -ne 0 ]; then
  echo "Erro ao entrar no ambiente chroot"
  exit 1
fi

echo "Instalação inicial concluída com sucesso!"

