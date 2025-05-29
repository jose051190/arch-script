#!/bin/bash

# =============================================================================
# Script de instalação e configuração de fontes no Arch Linux
# Baseado nas melhores práticas da ArchWiki
# =============================================================================

set -e  # Encerra o script se ocorrer qualquer erro

# =============================================================================
# Função de backup
# =============================================================================
backup_file() {
  if [[ -f "$1" ]]; then
    cp -v "$1" "$1.bak"
    echo "Backup criado: $1.bak"
  fi
}

# =============================================================================
# Atualização do sistema
# =============================================================================
echo "Atualizando sistema..."
sudo pacman -Syu --needed

# =============================================================================
# Instalação de fontes recomendadas
# =============================================================================
echo "Instalando fontes padrão..."
sudo pacman -S --needed \
  ttf-dejavu \
  ttf-liberation \
  noto-fonts \
  noto-fonts-emoji

# =============================================================================
# Instalação de Nerd Fonts
# =============================================================================
echo "Instalando Nerd Fonts..."
yay -S --needed \
  ttf-fira-code-nerd \
  ttf-hack-nerd \
  ttf-meslo-nerd

# =============================================================================
# Instalação de fontes da Microsoft
# =============================================================================
echo "Instalando Microsoft Fonts (EULA obrigatória)..."
yay -S --needed ttf-ms-fonts

# =============================================================================
# Configuração do Fontconfig
# =============================================================================
echo "Configurando Fontconfig..."

FONTCONFIG_DIR="$HOME/.config/fontconfig"
FONTCONFIG_FILE="$FONTCONFIG_DIR/fonts.conf"

mkdir -p "$FONTCONFIG_DIR"

# Backup da configuração existente
backup_file "$FONTCONFIG_FILE"

cat > "$FONTCONFIG_FILE" <<EOF
<?xml version='1.0'?>
<!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
<fontconfig>
  <match target="font">
    <edit name="antialias" mode="assign">
      <bool>true</bool>
    </edit>
    <edit name="hinting" mode="assign">
      <bool>true</bool>
    </edit>
    <edit name="rgba" mode="assign">
      <const>rgb</const>
    </edit>
    <edit name="hintstyle" mode="assign">
      <const>hintslight</const>
    </edit>
  </match>
</fontconfig>
EOF

echo "Fontconfig configurado em: $FONTCONFIG_FILE"

# =============================================================================
# Configuração do FreeType
# =============================================================================
echo "Configurando FreeType..."

FREETYPE_CONF="/etc/profile.d/freetype2.sh"

# Backup da configuração existente
sudo bash -c "backup_file '$FREETYPE_CONF'"

# Nota: desde 2020 o freetype2 usa v40 por padrão.
# Esta configuração pode ser opcional nas versões recentes do Arch.
echo "Adicionando TT_CONFIG no $FREETYPE_CONF..."

sudo bash -c "echo 'export TT_CONFIG=\"truetype:interpreter-version=40\"' >> '$FREETYPE_CONF'"

# =============================================================================
# Atualizando cache de fontes
# =============================================================================
echo "Atualizando cache de fontes..."
fc-cache -fv

# =============================================================================
# Remoção de pacotes órfãos (opcional)
# =============================================================================
echo "Deseja remover pacotes órfãos? [s/N]"
read -r resposta
if [[ \$resposta =~ ^[sS]$ ]]; then
  sudo pacman -Rns \$(pacman -Qdtq) || echo "Nenhum pacote órfão encontrado."
else
  echo "Remoção de órfãos ignorada."
fi

# =============================================================================
# Finalização
# =============================================================================
echo "Configuração de fontes concluída com sucesso!"
