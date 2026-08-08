#!/bin/bash
# Установка окружения для slowloris-теста в Termux (Node.js реализация, event-loop, держит больше сокетов).
# Запуск: curl -o install.sh https://raw.githubusercontent.com/AndriiMSN/slowattack_bash/main/install.sh
#         bash install.sh

set -e

echo "[+] Обновляю пакеты Termux..."
pkg update -y

echo "[+] Ставлю Node.js..."
pkg install -y nodejs

echo "[+] Ставлю slowloris-attack (npm, команда slowattack)..."
npm install -g slowloris-attack

echo "[+] Готово. Запуск атаки:"
echo "    curl -o run.sh https://raw.githubusercontent.com/AndriiMSN/slowattack_bash/main/run.sh"
echo "    bash run.sh <HOST> <PORT> <SOCKETS>"
