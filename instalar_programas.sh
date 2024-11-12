#!/bin/bash

# Verifica se o Flatpak está instalado, senão, instala
if ! command -v flatpak &> /dev/null
then
    echo "Flatpak não está instalado. Instalando o Flatpak..."
    sudo pacman -Syu flatpak --noconfirm
fi

# Adiciona o repositório Flathub se ainda não estiver configurado
if ! flatpak remote-list --user | grep -q "flathub"; then
    echo "Adicionando o repositório Flathub..."
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Lista de pacotes para instalação
pacotes=(
    com.hunterwittenborn.Celeste
    org.gnome.DejaDup
    org.gnome.Todo
    com.github.tchx84.Flatseal
    io.github.giantpinkrobots.flatsweep
    com.github.neithern.g4music
    org.gnome.FontManager
    com.heroicgameslauncher.hgl
    page.codeberg.libre_menu_editor.LibreMenuEditor
    com.nextcloud.desktopclient.nextcloud
    org.onlyoffice.desktopeditors
    com.vysp3r.ProtonPlus
    app.devsuite.Ptyxis
    org.gnome.Solanum
    com.valvesoftware.Steam
    org.telegram.desktop
    com.visualstudio.code
    com.borgbase.Vorta
)

# Instala cada pacote da lista para o usuário atual
for pacote in "${pacotes[@]}"; do
    echo "Instalando $pacote para o usuário..."
    flatpak install --user -y flathub "$pacote"
done

echo "Instalação concluída!"

