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

# Criar tabela de partição MBR e particionar
echo "Criando tabela de partição MBR no disco $disco..."
parted $disco mklabel msdos

echo "Criando partição raiz com alinhamento de 1 MiB..."
parted $disco mkpart primary ext4 1MiB 100%

# Exibir partições criadas
echo "Partições criadas:"
parted $disco print

# Pedir para o usuário confirmar a partição raiz
echo "Digite a partição raiz (e.g., /dev/sda1): "
read particao_raiz

# Verificar se a partição existe
if [ ! -b "$particao_raiz" ]; then
  echo "Partição raiz inválida: $particao_raiz"
  exit 1
fi

# Formatar a partição raiz
echo "Formatando a partição raiz com Ext4..."
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
pacstrap -K /mnt base linux linux-firmware nano base-devel intel-ucode networkmanager network-manager-applet bash-completion linux-headers grub
if [ $? -ne 0 ]; then
  echo "Erro ao instalar pacotes essenciais"
  exit 1
fi

# Gerar o fstab
echo "Gerando o fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
if [ $? -ne 0 ]; then
  echo "Erro ao gerar o fstab"
  exit 1
fi

# Configurar o GRUB
echo "Configurando o GRUB..."
arch-chroot /mnt /bin/bash <<EOF
grub-install --target=i386-pc $disco
if [ $? -ne 0 ]; then
  echo "Erro ao instalar o GRUB"
  exit 1
fi

grub-mkconfig -o /boot/grub/grub.cfg
if [ $? -ne 0 ]; then
  echo "Erro ao gerar o arquivo de configuração do GRUB"
  exit 1
fi
EOF

# Copiar o segundo script para o ambiente chroot
echo "Copiando o segundo script para o ambiente chroot..."
cp arch_netbook_part2.sh /mnt/

# Tornar o script executável dentro do ambiente chroot
chmod +x /mnt/arch_netbook_part2.sh

# Invocar o segundo script dentro do ambiente chroot
echo "Executando o segundo script no ambiente chroot..."
arch-chroot /mnt /bin/bash /arch_netbook_part2.sh

# Remover o script do ambiente chroot após execução
rm /mnt/arch_netbook_part2.sh

# Finalização
echo "Configuração completa! Você pode reiniciar o sistema."