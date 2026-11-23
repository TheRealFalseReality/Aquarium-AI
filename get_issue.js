const { spawn } = require('child_process');

const mcp = spawn('npx.cmd', ['-y', 'firebase-tools@latest', 'mcp'], {
    stdio: ['pipe', 'pipe', 'inherit'],
    shell: true
});

let buffer = '';

mcp.stdout.on('data', (data) => {
    buffer += data.toString();
    if (buffer.includes('"id":1')) {
        console.log("FINAL OUTPUT 1:");
        console.log(buffer);
        process.exit(0);
    }
});

const req = {
    jsonrpc: '2.0',
    id: 1,
    method: 'tools/call',
    params: {
        name: 'crashlytics_get_issue',
        arguments: {
            appId: '1:209151214292:android:f88d075a89001fe2c8b141',
            issueId: '0464874fc8e157e63f13334d77bdc568'
        }
    }
};

mcp.stdin.write(JSON.stringify(req) + '\n');
