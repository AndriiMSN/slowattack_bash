#!/bin/bash
# Установка окружения для slowloris-теста в Termux.
# Запуск: curl -o install.sh https://raw.githubusercontent.com/AndriiMSN/slowattack_bash/main/install.sh && bash install.sh

set -e

echo "[+] Обновляю пакеты Termux..."
pkg update -y

echo "[+] Ставлю python..."
pkg install -y python

echo "[+] Ставлю slowloris (gkbrk, PyPI)..."
pip install --break-system-packages slowloris

echo "[+] Готово. Запуск атаки:"
echo "    curl -o run.sh https://raw.githubusercontent.com/AndriiMSN/slowattack_bash/main/run.sh && bash run.sh <HOST> <PORT> <SOCKETS>"
