#!/bin/bash

# Variáveis
SOURCE="jose@192.168.1.20:/home/jose/Homelab/Backups/Backup-full/"  # Origem do backup
DESTINATION="/mnt/"  # Destino (ajuste conforme necessário)
LOG_FOLDER="/mnt/home/jose/Documentos/LogsDeRestauracao"  # Pasta para armazenar logs
LOGFILE="$LOG_FOLDER/restore_$(date +%Y%m%d_%H%M%S).log"  # Caminho do arquivo de log

# Cria a pasta de logs se ela não existir
mkdir -p "$LOG_FOLDER"

# Executa o comando de restauração via SSH e registra a saída
{
    echo "Iniciando a restauração em $(date)"
    rsync -aAXHv --delete --numeric-ids -e ssh "$SOURCE" "$DESTINATION"
    echo "Restauração concluída em $(date)"
} | tee "$LOGFILE"

# Verifica se o rsync foi bem-sucedido
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    echo "Erro: A restauração falhou. Verifique o log para mais detalhes." | tee -a "$LOGFILE"
    exit 1
fi

