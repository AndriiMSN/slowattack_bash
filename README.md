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
