const { spawn } = require('child_process');
const mcp = spawn('npx.cmd', ['-y', 'firebase-tools@latest', 'mcp'], { stdio: ['pipe', 'pipe', 'inherit'], shell: true });
let buffer = '';
mcp.stdout.on('data', (data) => {
    buffer += data.toString();
    if (buffer.includes('"id":1')) {
        console.log(buffer);
        process.exit(0);
    }
});
const req = { jsonrpc: '2.0', id: 1, method: 'tools/list', params: {} };
mcp.stdin.write(JSON.stringify(req) + '\n');
