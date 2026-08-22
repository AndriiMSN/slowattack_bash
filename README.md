# slowattack_bash

Набор скриптов для нагрузочного тестирования устойчивости **собственного** сервера/сети к атакам класса Slowloris (HTTP connection exhaustion) и SYN flood. Разработано и используется как часть практической лаборатории по кибербезопасности — методология и результаты тестов описаны в `REPORT.md`.

## ⚠️ Только для собственной инфраструктуры

Все скрипты в этом репозитории предназначены **исключительно** для тестирования серверов и сетей, которыми вы владеете или на тестирование которых у вас есть явное письменное разрешение. Использование против чужой инфраструктуры без согласия — незаконно. Автор не несёт ответственности за использование не по назначению.

## Что внутри

| Файл | Назначение |
|---|---|
| `install.sh` | Установка окружения (Node.js, зависимости) в Termux/Linux |
| `run.sh` | Запуск Slowloris-теста (обёртка над `vendor-slowloris`, поддержка нескольких параллельных процессов) |
| `slowloris.sh` | Альтернативный интерфейс запуска той же библиотеки, с флагами в стиле getopts |
| `synflood.sh` | SYN flood тест на базе `nping` (пакет nmap) |
| `vendor-slowloris/` | Форк [yosif111/Slowloris](https://github.com/yosif111/Slowloris) (Node.js, event-loop) с поддержкой множественных параллельных инстансов |

## Установка

**Termux (Android):**
```bash
curl -o install.sh https://raw.githubusercontent.com/AndriiMSN/slowattack_bash/main/install.sh
bash install.sh
```

**Linux/macOS:**
```bash
git clone https://github.com/AndriiMSN/slowattack_bash.git
cd slowattack_bash
npm install --prefix vendor-slowloris
```

`install.sh` ставит Node.js и git (если их нет), клонирует/обновляет репозиторий в `$HOME/slowattack_bash`, устанавливает npm-зависимости `vendor-slowloris`.

## Использование

### Slowloris (`run.sh`)

```bash
bash run.sh <HOST> [PORT] [SOCKETS] [DURATION_MS] [INSTANCES]
```

| Параметр | По умолчанию | Описание |
|---|---|---|
| `HOST` | — (обязателен) | IP или домен целевого сервера |
| `PORT` | `80` | Порт; `443` автоматически переключает схему на `https` |
| `SOCKETS` | `1000` | Число сокетов на один процесс |
| `DURATION_MS` | без ограничения | Длительность атаки в миллисекундах; без значения — до `Ctrl+C` |
| `INSTANCES` | `20` | Число параллельных процессов (для распределения нагрузки за пределы лимита файловых дескрипторов одного процесса) |

Примеры:
```bash
# HTTP, 1000 сокетов x 20 процессов на порт 80
bash run.sh 192.0.2.10

# HTTPS, 500 сокетов x 10 процессов, автоматически https
bash run.sh 192.0.2.10 443 500 0 10

# С ограничением по времени - 60 секунд
bash run.sh 192.0.2.10 80 1000 60000 20
```

Голый IP-адрес автоматически оборачивается в `<ip>.sslip.io` — библиотека требует URL с доменной зоной, `sslip.io` резолвится обратно в тот же IP без необходимости покупать домен.

### SYN flood (`synflood.sh`)

Требует `nping` (пакет `nmap`) и права на raw-сокеты (root в Linux/Termux, администратор в Windows с установленным Npcap).

```bash
./synflood.sh -h <HOST> [-p PORT] [-r RATE_PPS] [-t DURATION_SEC]
```

| Флаг | По умолчанию | Описание |
|---|---|---|
| `-h` | — (обязателен) | Целевой хост |
| `-p` | `80` | Целевой порт |
| `-r` | `5000` | Пакетов в секунду |
| `-t` | `0` (бесконечно) | Длительность в секундах |

Пример:
```bash
sudo ./synflood.sh -h 192.0.2.10 -p 80 -r 5000 -t 30
```

## Развёртывание тестового сервера-мишени

Ниже — минимальная конфигурация **собственного** сервера (использовался DigitalOcean droplet, Ubuntu), на который затем направлялись `run.sh`/`synflood.sh`. Разворачивайте только то, чем реально владеете.

**1. Создание дроплета:** Ubuntu 22.04/24.04, план от $6/мес (1 vCPU/1GB RAM достаточно — тест бьёт по числу соединений, не по мощности CPU).

**2. Базовая настройка и firewall:**
```bash
apt update && apt upgrade -y
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```
Дополнительно — DigitalOcean Cloud Firewall (Networking → Firewalls) с теми же правилами как второй независимый слой фильтрации.

**3. Веб-сервер (Apache, с prefork MPM — исторически наиболее чувствителен к Slowloris, удобен для демонстрации эффекта):**
```bash
apt install -y apache2
a2dismod mpm_event
a2enmod mpm_prefork
systemctl restart apache2
```

**4. Лимиты воркеров — считать от реального объёма RAM, не завышать:**
```bash
# /etc/apache2/mods-available/mpm_prefork.conf
ServerLimit             150
StartServers            5
MinSpareServers         5
MaxSpareServers         10
MaxRequestWorkers       150
MaxConnectionsPerChild  0
```
(на 1GB RAM попытка задать `ServerLimit`/`MaxRequestWorkers` в тысячи приводит к `AH00159: fork: Unable to fork new process` — нехватка памяти, а не защита; подробности в `REPORT.md`)

**5. Самоподписанный TLS-сертификат для порта 443 (домен не нужен):**
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/apache-selfsigned.key \
  -out /etc/ssl/certs/apache-selfsigned.crt \
  -subj "/CN=$(curl -s ifconfig.me)"

a2enmod ssl
a2ensite default-ssl
systemctl restart apache2
```

**6. Проверка снаружи (с другого устройства, не с самого сервера):**
```bash
curl -I http://YOUR_DROPLET_IP/
curl -Ik https://YOUR_DROPLET_IP/
```
Оба должны вернуть `200 OK` — сервер готов как цель для `run.sh`/`synflood.sh`.

Полный разбор hardening после проведения теста (таймауты `RequestReadTimeout`, `mod_evasive`, сравнение с nginx) — в `REPORT.md`, раздел 4.

## Мониторинг во время теста

На тестируемом сервере — число установленных/полуоткрытых соединений и статус веб-сервера:
```bash
ss -tan state established | wc -l      # для Slowloris
ss -tan state syn-recv | wc -l         # для SYN flood
tail -f /var/log/apache2/error.log
```

Полный набор команд мониторинга и методология описаны в `REPORT.md`.

## Связанная документация в этом репозитории

- `REPORT.md` — методология тестирования, результаты, рекомендации по защите (rate-limiting, таймауты Apache, pfSense/OpenWrt)
- `WIFI-CAMERA-AUDIT.md` — смежный аудит перехвата трафика в Wi-Fi сети

## Требования

- Node.js ≥ 16 (для Slowloris-скриптов)
- nmap/nping (для SYN flood)
- Termux (Android) или Linux/macOS/Windows (Git Bash)
