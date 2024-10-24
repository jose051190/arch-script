#!/bin/bash

# Variáveis
SOURCE="/"
DESTINATION="jose@192.168.1.20:/home/jose/Homelab/Backups/Backup-full"
LOG_FOLDER="/home/jose/Documentos/LogsDeBackup"  # Pasta para armazenar os logs
LOGFILE="$LOG_FOLDER/backup_$(date +%Y%m%d_%H%M%S).log"  # Caminho completo para o arquivo de log

# Cria a pasta de logs se ela não existir
mkdir -p "$LOG_FOLDER"

# Exclui diretórios dinâmicos e desnecessários
EXCLUDES=(
    --exclude='/dev/*'
    --exclude='/proc/*'
    --exclude='/sys/*'
    --exclude='/tmp/*'
    --exclude='/run/*'
    --exclude='/mnt/*' # Inclui o destino do backup
    --exclude='/media/*'
    --exclude='/lost+found/'
    --exclude='/swapfile' # Excluir arquivo de swap, ajuste conforme necessário
    --exclude='/home/*/.thumbnails/*'
    --exclude='/home/*/.cache/mozilla/*'
    --exclude='/home/*/.cache/chromium/*'
    --exclude='/home/*/.local/share/Trash/*'
    --exclude='/home/*/.gvfs'
    --exclude='/var/lib/dhcpcd/*'
    --exclude='/home/*/Documentos/*'  # Excluir a pasta Documentos
)

# Opções adicionais do rsync
OPTIONS=(
    -aAXHv  # -a: modo arquivo, -A: preservar ACLs, -X: preservar atributos estendidos, -H: preservar links duros, -v: modo verbose
    --delete
    -S
    --numeric-ids
    --info=progress2
    -x
)

# Executa o comando de backup remotamente via SSH e registra a saída
{
    echo "Iniciando o backup em $(date)"
    sudo rsync "${OPTIONS[@]}" "${EXCLUDES[@]}" -e ssh "$SOURCE" "$DESTINATION"
    echo "Backup concluído em $(date)"
} | tee "$LOGFILE"

# Verifica se o rsync foi bem-sucedido
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    echo "Erro: O backup falhou. Verifique o log para mais detalhes." | tee -a "$LOGFILE"
    exit 1
fi

