#!/usr/bin/env bash
# set -e: Sai imediatamente se um comando falhar.
# set -u: Trata variáveis não definidas como erro e sai.
# set -o pipefail: Se qualquer comando em um pipeline falhar, o pipeline inteiro falha.
set -euo pipefail

# --- Configuração Inicial ---
echo "Configurando fontes no Arch Linux (Wayland/Hyprland)..."
echo "Este script automatiza a instalação e configuração de fontes."
echo "Será solicitado o EULA da Microsoft para fontes proprietárias (ttf-ms-fonts)."
echo "Certifique-se de ter o 'yay' instalado e configurado para o AUR."
echo ""

FONTCONFIG_USER_DIR="$HOME/.config/fontconfig"
FONTCONFIG_USER_CONF="$FONTCONFIG_USER_DIR/fonts.conf"
FREETYPE_CONF="/etc/profile.d/freetype2.sh"

# --- 1. Atualizar Sistema ---
echo "1. Atualizando sistema..."
# É crucial realizar uma atualização completa do sistema para evitar problemas de dependência. [1, 2, 3, 4, 5, 6]
sudo pacman -Syu --needed |
| { echo "Erro ao atualizar o sistema. Saindo."; exit 1; }
echo "Sistema atualizado."
echo ""

# --- 2. Instalar Fontes (Pacman) ---
echo "2. Instalando fontes essenciais, de desenvolvimento (Nerd Fonts) e ícones..."
# Usando --needed para garantir idempotência: pacotes já instalados não serão reinstalados. [1, 4, 5]
sudo pacman -S --needed \
    ttf-dejavu \
    ttf-liberation \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    ttf-caladea \
    ttf-carlito \
    ttf-opensans \
    ttf-roboto \
    ttf-ubuntu-font-family \
    ttf-inter \
    ttf-lato \
    ttf-jetbrains-mono-nerd \
    ttf-firacode-nerd \
    ttf-hack-nerd \
    adobe-source-code-pro-fonts \
    ttf-font-awesome |
| { echo "Erro ao instalar fontes via pacman. Saindo."; exit 1; }
echo "Fontes de sistema, desenvolvimento e ícones instaladas."
echo ""

# --- 3. Instalar Fontes Microsoft e Nerd Fonts adicionais (AUR com yay) ---
echo "3. Instalando fontes Microsoft e Nerd Fonts adicionais via AUR."
echo "ATENÇÃO: A instalação de 'ttf-ms-fonts' requer a aceitação do EULA da Microsoft."
echo "Este EULA impõe restrições de uso e redistribuição (e.g., não para fins lucrativos ou modificação)."
echo "Certifique-se de ler e compreender o EULA antes de prosseguir. "
read -p "Pressione Enter para continuar e aceitar o EULA (se solicitado pelo yay)..."

echo "ATENÇÃO: Ao instalar pacotes do AUR, é altamente recomendável revisar o PKGBUILD para garantir a segurança. [7, 8, 9, 6]"
read -p "Pressione Enter para iniciar a instalação via yay..."

# Usando --needed para garantir idempotência. [8, 9]
# O tratamento de erro aqui não sai do script, permitindo que continue mesmo se o AUR falhar.
yay -S --needed \
    ttf-ms-fonts \
    ttf-office-2007-fonts \
    ttf-ms-win11-auto \
    ttf-inconsolata-nerd |
| { echo "Aviso: Erro ao instalar fontes Microsoft/Nerd Fonts adicionais via yay. Verifique o EULA e as dependências. O script continuará."; }
echo "Fontes Microsoft e Nerd Fonts adicionais instaladas (se o EULA foi aceito e não houve erros)."
echo ""

# --- 4. Configurar Fontconfig Presets ---
echo "4. Habilitando presets do Fontconfig..."
# Criando links simbólicos para presets globais. [10, 11]
sudo ln -sf /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d/ |
| { echo "Erro ao linkar 70-no-bitmaps.conf."; }
sudo ln -sf /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d/ |
| { echo "Erro ao linkar 10-sub-pixel-rgb.conf."; }
sudo ln -sf /etc/fonts/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d/ |
| { echo "Erro ao linkar 11-lcdfilter-default.conf."; }
echo "Presets do Fontconfig habilitados."
echo ""

# --- 5. Criar/Editar ~/.config/fontconfig/fonts.conf ---
echo "5. Criando/Atualizando $FONTCONFIG_USER_CONF..."
# Configurações de fontes específicas do usuário têm precedência sobre as globais. 
mkdir -p "$FONTCONFIG_USER_DIR"
cat << EOF > "$FONTCONFIG_USER_CONF"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
    <match target="font">
        <edit name="antialias" mode="assign"><bool>true</bool></edit>
        <edit name="hinting" mode="assign"><bool>true</bool></edit>
        <edit name="rgba" mode="assign"><const>rgb</const></edit>
        <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
    </match>
    <alias>
        <family>serif</family>
        <prefer>
            <family>Noto Serif</family>
            <family>Noto Color Emoji</family>
            <family>Noto Emoji</family>
        </prefer>
    </alias>
    <alias>
        <family>sans-serif</family>
        <prefer>
            <family>Noto Sans</family>
            <family>Noto Color Emoji</family>
            <family>Noto Emoji</family>
        </prefer>
    </alias>
    <alias>
        <family>monospace</family>
        <prefer>
            <family>JetBrainsMono Nerd Font</family>
            <family>FiraCode Nerd Font</family>
            <family>Hack Nerd Font</family>
            <family>Inconsolata Nerd Font</family>
            <family>Noto Sans Mono</family>
            <family>Noto Color Emoji</family>
            <family>Noto Emoji</family>
        </prefer>
    </alias>
</fontconfig>
EOF
echo "Arquivo $FONTCONFIG_USER_CONF criado/atualizado."
echo ""

# --- 6. Configurar FreeType ---
echo "6. Configurando FreeType..."
# A versão 40 do interpretador TrueType é o padrão no FreeType 2.7+ e oferece bom equilíbrio entre velocidade e qualidade. [12, 13]
if grep -q "^#export FREETYPE_PROPERTIES=\"truetype:interpreter-version=40\"" "$FREETYPE_CONF"; then
    sudo sed -i 's/^#export FREETYPE_PROPERTIES="truetype:interpreter-version=40"/export FREETYPE_PROPERTIES="truetype:interpreter-version=40"/' "$FREETYPE_CONF"
    echo "Configuração do FreeType atualizada (descomentada)."
elif! grep -q "export FREETYPE_PROPERTIES=\"truetype:interpreter-version=40\"" "$FREETYPE_CONF"; then
    echo 'export FREETYPE_PROPERTIES="truetype:interpreter-version=40"' | sudo tee -a "$FREETYPE_CONF"
    echo "Configuração do FreeType adicionada."
else
    echo "Configuração do FreeType já presente e ativa."
fi
echo ""

# --- 7. Atualizar Cache de Fontes ---
echo "7. Atualizando cache de fontes..."
# É crucial executar fc-cache -fv como root para atualizar a cache global de fontes. 
sudo fc-cache -fv |
| { echo "Erro ao atualizar o cache de fontes. Saindo."; exit 1; }
echo "Cache de fontes atualizado."
echo ""

# --- Mensagem Final ---
echo "----------------------------------------------------"
echo "Instalação e configuração de fontes concluídas!"
echo "Para aplicar as mudanças, você pode precisar:"
echo "  - Reiniciar seus aplicativos."
echo "  - Fazer logout e login na sua sessão (Hyprland)."
echo "  - Reiniciar o sistema para garantir todas as configurações."
echo ""
echo "Recomendações adicionais para manutenção do sistema:"
echo "  - Verifique regularmente por ficheiros '.pacnew' em /etc (use 'pacdiff') para mesclar novas configurações de pacotes. [4]"
echo "  - Remova pacotes órfãos (pacotes instalados como dependências que não são mais necessários) com 'pacman -Qdt' e 'yay -Qdt'. [4, 9]"
echo "----------------------------------------------------"
