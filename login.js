const { spawn } = require('child_process');
const mcp = spawn('npx.cmd', ['-y', 'firebase-tools@latest', 'mcp'], { stdio: ['pipe', 'pipe', 'inherit'], shell: true });
mcp.stdout.on('data', (data) => {
    const s = data.toString();
    if (s.includes('"id":1')) {
        console.log(s);
        process.exit(0);
    }
});
mcp.stdin.write(JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name: 'firebase_login', arguments: {} } }) + '\n');
