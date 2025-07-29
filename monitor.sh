#!/bin/bash
SITE_URL="http://localhost"
LOG_FILE="/var/log/monitoramento.log"
WEBHOOK_URL="usei meu webhook aqui"

HTTP_STATUS=\$(curl -o /dev/null -s -w "%{http_code}" \$SITE_URL)  # faz uma requisição a url, ignorando a parte html e escrevendo o codigo http, que simboliza o status do site.
DATA_ATUAL=\$(date +"%d/%m/%Y %H:%M:%S")

# 200 é o codigo de uma requisicao web bem sucedida, qualquer outro codigo, o site esta com problemas
if [ "\$HTTP_STATUS" -ne 200 ]; then 
    MENSAGEM="[ALERTA] O site \$SITE_URL está OFFLINE! Status: \$HTTP_STATUS"
    echo "\$DATA_ATUAL - \$MENSAGEM" >> \$LOG_FILE
    curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"\$MENSAGEM\"}" \$WEBHOOK_URL
else
    MENSAGEM="[INFO] O site \$SITE_URL está funcionando normalmente. Status: \$HTTP_STATUS"
    echo "\$DATA_ATUAL - \$MENSAGEM" >> \$LOG_FILE
fi
