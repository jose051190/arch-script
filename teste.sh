#!/bin/bash

# ----------------------------------------------------------
# Script   : install_netbook.sh
# Descrição: Script interativo para instalação e configuração do Arch Linux para netbooks
# Autor    : Seu Nome
# ----------------------------------------------------------

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute o script como root."
  exit 1
fi

# Função para verificar o status dos comandos
check_command() {
  if [ $? -ne 0 ]; then
    echo "Erro ao executar: $1"
    exit 1
  fi
}

# Variáveis Globais
user=""
hostname=""
root_password=""
user_password=""
disk=""
bios_or_uefi=""
graphics_env=""
swap_size="2G"  # Tamanho padrão do swap

# Função para exibir o menu principal
menu_principal() {
    clear
    echo "----------------------------------------------------------"
    echo " SCRIPT DE INSTALAÇÃO DO ARCH LINUX - MENU PRINCIPAL"
    echo "----------------------------------------------------------"
    echo "1 - Configurar Disco (BIOS/UEFI)"
    echo "2 - Definir Hostname"
    echo "3 - Criar Usuário e Definir Senhas"
    echo "4 - Selecionar Ambiente Gráfico"
    echo "5 - Instalar Pacotes Essenciais e Adicionais"
    echo "6 - Finalizar Instalação e Reiniciar"
    echo "7 - Sair"
    echo "----------------------------------------------------------"
    read -p "Escolha uma opção: " opcao
    case $opcao in
        1) configurar_disco ;;
        2) definir_hostname ;;
        3) criar_usuario ;;
        4) selecionar_ambiente_grafico ;;
        5) instalar_pacotes ;;
        6) finalizar_instalacao ;;
        7) sair ;;
        *) echo "Opção inválida. Tente novamente."; sleep 2; menu_principal ;;
    esac
}

# Função para configurar o disco
configurar_disco() {
    clear
    echo "----------------------------------------------------------"
    echo " CONFIGURAÇÃO DO DISCO (BIOS/UEFI)"
    echo "----------------------------------------------------------"
    echo "1 - BIOS"
    echo "2 - UEFI"
    echo "3 - Voltar ao Menu Principal"
    echo "----------------------------------------------------------"
    read -p "Escolha o modo de instalação (1-3): " modo
    case $modo in
        1) bios_or_uefi="bios"; echo "Modo BIOS selecionado."; sleep 1 ;;
        2) bios_or_uefi="uefi"; echo "Modo UEFI selecionado."; sleep 1 ;;
        3) menu_principal ;;
        *) echo "Opção inválida. Tente novamente."; sleep 2; configurar_disco ;;
    esac

    # Listar discos disponíveis
    echo "Discos disponíveis:"
    lsblk -d -o NAME,SIZE,MODEL | grep -vE "loop|sr0|zram" | awk 'NR>1 {print NR-1 ") " $0}'
    echo "Digite o número do disco que deseja particionar: "
    read num_disco

    # Obter o disco selecionado
    disco=$(lsblk -d -o NAME | grep -vE "loop|sr0|zram" | awk -v n="$num_disco" 'NR==n+1 {print $1}')
    if [ -z "$disco" ]; then
      echo "Número de disco inválido."
      sleep 2
      configurar_disco
    fi
    disco="/dev/$disco"
    echo "Disco selecionado: $disco"
    sleep 1

    # Criar tabela de partição
    echo "Criando tabela de partição ${bios_or_uefi^^} no disco $disco..."
    parted $disco mklabel msdos
    check_command "Criar tabela de partição"

    # Criar partição raiz
    echo "Criando partição raiz com alinhamento de 1 MiB..."
    parted $disco mkpart primary ext4 1MiB 100%
    check_command "Criar partição raiz"

    # Exibir partições criadas
    echo "Partições criadas:"
    parted $disco print
    sleep 1

    # Selecionar partição raiz
    echo "Digite a partição raiz (e.g., ${disco}1): "
    read particao_raiz
    if [ ! -b "$particao_raiz" ]; then
      echo "Partição raiz inválida: $particao_raiz"
      sleep 2
      configurar_disco
    fi

    # Formatar a partição raiz
    echo "Formatando a partição raiz com Ext4..."
    mkfs.ext4 $particao_raiz
    check_command "Formatar partição raiz"

    # Montar a partição raiz
    echo "Montando a partição raiz em /mnt..."
    mount $particao_raiz /mnt
    check_command "Montar partição raiz"

    echo "Configuração do disco concluída!"
    sleep 2
    menu_principal
}

# Função para definir o hostname
definir_hostname() {
    clear
    echo "----------------------------------------------------------"
    echo " DEFINIR HOSTNAME"
    echo "----------------------------------------------------------"
    read -p "Digite o hostname desejado: " hostname
    if [[ -z "$hostname" ]]; then
      echo "Hostname não pode ser vazio."
      sleep 2
      definir_hostname
    fi

    echo "Configurando hostname..."
    echo "$hostname" > /mnt/etc/hostname
    check_command "Configurar hostname"

    # Configurar /etc/hosts
    cat <<EOL > /mnt/etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    $hostname.localdomain $hostname
EOL
    check_command "Configurar /etc/hosts"

    echo "Hostname configurado como '$hostname'."
    sleep 2
    menu_principal
}

# Função para criar usuário e definir senhas
criar_usuario() {
    clear
    echo "----------------------------------------------------------"
    echo " CRIAR USUÁRIO E DEFINIR SENHAS"
    echo "----------------------------------------------------------"
    read -p "Digite o nome do usuário: " user
    if [[ -z "$user" ]]; then
      echo "Nome de usuário não pode ser vazio."
      sleep 2
      criar_usuario
    fi

    # Criar usuário
    useradd -mG wheel "$user"
    check_command "Criar usuário $user"

    # Definir senha do usuário
    echo "Definindo senha para o usuário $user..."
    passwd "$user"
    check_command "Definir senha do usuário $user"

    # Definir senha do root
    echo "Definindo senha para o usuário root..."
    passwd
    check_command "Definir senha do root"

    # Configurar sudoers
    sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /mnt/etc/sudoers
    check_command "Configurar sudoers para o grupo wheel"

    echo "Usuário '$user' criado e senhas definidas."
    sleep 2
    menu_principal
}

# Função para selecionar ambiente gráfico
selecionar_ambiente_grafico() {
    clear
    echo "----------------------------------------------------------"
    echo " SELECIONAR AMBIENTE GRÁFICO"
    echo "----------------------------------------------------------"
    echo "1 - Openbox"
    echo "2 - XFCE"
    echo "3 - KDE Plasma"
    echo "4 - GNOME"
    echo "5 - Voltar ao Menu Principal"
    echo "----------------------------------------------------------"
    read -p "Escolha uma opção: " env_choice
    case $env_choice in
        1) graphics_env="openbox tint2 obconf lxappearance lxappearance-obconf pcmanfm xarchiver unrar xdg-utils xdg-user-dirs plymouth" ;;
        2) graphics_env="xfce4 xfce4-goodies lightdm lightdm-gtk-greeter" ;;
        3) graphics_env="plasma-meta kde-applications sddm sddm-kcm" ;;
        4) graphics_env="gnome gnome-extra gdm" ;;
        5) menu_principal ;;
        *) echo "Opção inválida. Tente novamente."; sleep 2; selecionar_ambiente_grafico ;;
    esac

    echo "Ambiente gráfico selecionado: $graphics_env"
    sleep 1
    menu_principal
}

# Função para instalar pacotes
instalar_pacotes() {
    clear
    echo "----------------------------------------------------------"
    echo " INSTALANDO PACOTES ESSENCIAIS E ADICIONAIS"
    echo "----------------------------------------------------------"

    # Ajustar idioma e fuso horário
    echo "Configurando idioma e fuso horário..."
    ln -sf /usr/share/zoneinfo/America/Fortaleza /etc/localtime
    check_command "Configurar fuso horário"
    hwclock --systohc
    check_command "Configurar hardware clock"

    # Configurar locale
    sed -i 's/^#pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/' /etc/locale.gen
    check_command "Descomentar pt_BR.UTF-8 no locale.gen"
    locale-gen
    check_command "Gerar locale"
    echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
    check_command "Configurar LANG no locale.conf"

    # Habilitar NetworkManager
    systemctl enable NetworkManager
    check_command "Habilitar NetworkManager"

    # Configurar initramfs
    mkinitcpio -P
    check_command "Gerar initramfs"

    # Habilitar multilib no pacman.conf
    sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
    check_command "Habilitar multilib no pacman.conf"

    # Adicionar ILoveCandy no pacman.conf
    sed -i 's/^#Color/Color/' /etc/pacman.conf
    check_command "Descomentar Color no pacman.conf"
    sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
    check_command "Descomentar VerbosePkgLists no pacman.conf"
    sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
    check_command "Descomentar ParallelDownloads no pacman.conf"
    grep -q '^ParallelDownloads = 5' /etc/pacman.conf && sed -i '/^ParallelDownloads = 5/a ILoveCandy' /etc/pacman.conf || echo -e '\nParallelDownloads = 5\nILoveCandy' >> /etc/pacman.conf
    check_command "Adicionar ILoveCandy no pacman.conf"

    # Atualizar pacman
    pacman -Syu --noconfirm
    check_command "Atualizar pacman"

    # Instalar pacotes adicionais
    echo "Instalando pacotes adicionais..."
    pacman -S --needed --noconfirm chromium ristretto mpv vlc galculator leafpad
    check_command "Instalar pacotes adicionais"

    # Instalar pacotes do ambiente gráfico selecionado
    if [[ -n "$graphics_env" ]]; then
        echo "Instalando ambiente gráfico selecionado..."
        pacman -S --needed --noconfirm $graphics_env
        check_command "Instalar ambiente gráfico $graphics_env"

        # Configurar display manager
        case $graphics_env in
            *lightdm*)
                systemctl enable lightdm
                check_command "Habilitar LightDM"
                ;;
            *sddm*)
                systemctl enable sddm
                check_command "Habilitar SDDM"
                ;;
            *gdm*)
                systemctl enable gdm
                check_command "Habilitar GDM"
                ;;
            *)
                # Para Openbox, iniciar com startx
                echo "exec openbox-session" > /home/$user/.xinitrc
                check_command "Configurar .xinitrc para Openbox"
                chown $user:$user /home/$user/.xinitrc
                check_command "Alterar propriedade de .xinitrc para o usuário $user"
                ;;
        esac
    else
        echo "Nenhum ambiente gráfico selecionado."
    fi

    # Configurar GRUB para Plymouth (se necessário)
    if [[ "$graphics_env" == *plymouth* ]]; then
        echo "Configurando GRUB para Plymouth..."
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&splash rd.udev.log_priority=3 vt.global_cursor_default=0 /' /etc/default/grub
        check_command "Configurar GRUB para Plymouth"

        grub-mkconfig -o /boot/grub/grub.cfg
        check_command "Gerar configuração do GRUB"

        # Adicionar plymouth aos HOOKS no mkinitcpio.conf
        sed -i '/^HOOKS=/ s/\(base udev\)/\1 plymouth/' /etc/mkinitcpio.conf
        check_command "Adicionar plymouth aos HOOKS do mkinitcpio.conf"

        mkinitcpio -P
        check_command "Atualizar mkinitcpio"
    fi

    # Instalar drivers Intel (se necessário)
    if [[ "$graphics_env" == *openbox* ]]; then
        echo "Instalando drivers para GPUs Intel antigas..."
        pacman -S --needed --noconfirm mesa lib32-mesa xf86-video-intel xorg-server
        check_command "Instalar drivers Intel antigos"
    fi

    echo "Pacotes instalados com sucesso!"
    sleep 2
    menu_principal
}

# Função para finalizar a instalação e reiniciar
finalizar_instalacao() {
    clear
    echo "----------------------------------------------------------"
    echo " FINALIZANDO INSTALAÇÃO E PREPARANDO PARA REINICIAR"
    echo "----------------------------------------------------------"
    
    # Habilitar serviços essenciais
    systemctl enable systemd-timesyncd.service
    check_command "Habilitar systemd-timesyncd.service"

    # Finalizar chroot e desmontar
    echo "Desmontando partições..."
    umount -R /mnt
    check_command "Desmontar /mnt"

    echo "Instalação concluída! Reiniciando o sistema..."
    reboot
}

# Função para sair do script
sair() {
    echo "Saindo do script de instalação. Até logo!"
    exit 0
}

# Iniciar o script
menu_principal

