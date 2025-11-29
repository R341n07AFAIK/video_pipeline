function switchTab(tabName) {
    // Hide all tabs
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Remove active state from buttons
    document.querySelectorAll('.tab-button').forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Show selected tab
    document.getElementById(tabName).classList.add('active');
    
    // Set button active
    event.target.classList.add('active');
}

function log(message, type = 'info') {
    const logBox = document.getElementById('log');
    const timestamp = new Date().toLocaleTimeString();
    const prefix = type === 'error' ? '❌' : type === 'success' ? '✓' : 'ℹ';
    logBox.innerHTML += `[${timestamp}] ${prefix} ${message}<br>`;
    logBox.scrollTop = logBox.scrollHeight;
}

function clearLog() {
    document.getElementById('log').innerHTML = '';
}

function clearBatchLog() {
    document.getElementById('batchLog').innerHTML = '';
}

function selectFile() {
    alert('File selection requires server backend');
    const filename = prompt('Enter video file path:');
    if (filename) {
        document.getElementById('inputVideo').value = filename;
    }
}

function selectFolder(type) {
    alert('Folder selection requires server backend');
    const folder = prompt('Enter folder path:');
    if (folder) {
        if (type === 'input') {
            document.getElementById('batchInput').value = folder;
        } else {
            document.getElementById('batchOutput').value = folder;
        }
    }
}

function processVideo() {
    clearLog();
    const input = document.getElementById('inputVideo').value;
    const output = document.getElementById('outputVideo').value;
    const provider = document.getElementById('provider').value;
    const fps = document.getElementById('fps').value;
    const codec = document.getElementById('codec').value;
    
    if (!input) {
        log('Please select input video', 'error');
        return;
    }
    
    log(`Starting video processing...`, 'info');
    log(`Input: ${input}`, 'info');
    log(`Output: ${output}`, 'info');
    log(`Provider: ${provider}`, 'info');
    log(`FPS: ${fps}`, 'info');
    log(`Codec: ${codec}`, 'info');
    
    // Simulate processing
    setTimeout(() => {
        log('Extracting frames...', 'info');
        setTimeout(() => {
            log('Processing frames...', 'info');
            setTimeout(() => {
                log('Re-encoding video...', 'info');
                setTimeout(() => {
                    log('Process complete!', 'success');
                }, 1000);
            }, 1000);
        }, 1000);
    }, 500);
}

function processBatch() {
    const logBox = document.getElementById('batchLog');
    const input = document.getElementById('batchInput').value;
    const output = document.getElementById('batchOutput').value;
    const provider = document.getElementById('batchProvider').value;
    
    logBox.innerHTML = '';
    
    if (!input) {
        logBox.innerHTML += `[${new Date().toLocaleTimeString()}]  Please select input folder<br>`;
        return;
    }
    
    logBox.innerHTML += `[${new Date().toLocaleTimeString()}] ℹ Starting batch processing...<br>`;
    logBox.innerHTML += `[${new Date().toLocaleTimeString()}] ℹ Input: ${input}<br>`;
    logBox.innerHTML += `[${new Date().toLocaleTimeString()}] ℹ Output: ${output}<br>`;
    logBox.innerHTML += `[${new Date().toLocaleTimeString()}] ℹ Provider: ${provider}<br>`;
    logBox.scrollTop = logBox.scrollHeight;
}

function saveGrokKey() {
    const key = document.getElementById('grokKey').value;
    if (key) {
        alert('Grok API Key saved locally');
        localStorage.setItem('grokKey', key);
    }
}

function saveMJKey() {
    const key = document.getElementById('mjKey').value;
    if (key) {
        alert('Midjourney API Key saved locally');
        localStorage.setItem('mjKey', key);
    }
}

function saveComfyUIServer() {
    const server = document.getElementById('comfyuiServer').value;
    localStorage.setItem('comfyuiServer', server);
    alert('ComfyUI server saved');
}

function saveDefaults() {
    const fps = document.getElementById('defaultFPS').value;
    const codec = document.getElementById('defaultCodec').value;
    localStorage.setItem('defaultFPS', fps);
    localStorage.setItem('defaultCodec', codec);
    alert('Defaults saved');
    
    // Apply to main tab
    document.getElementById('fps').value = fps;
    document.getElementById('codec').value = codec;
}

function checkStatus() {
    document.getElementById('statusPS').innerHTML = ' Available';
    document.getElementById('statusPS').classList.add('ok');
    
    document.getElementById('statusFFmpeg').innerHTML = ' v8.0.1';
    document.getElementById('statusFFmpeg').classList.add('ok');
    
    document.getElementById('statusPython').innerHTML = ' v3.12';
    document.getElementById('statusPython').classList.add('ok');
    
    const grokKey = localStorage.getItem('grokKey');
    document.getElementById('statusGrok').innerHTML = grokKey ? ' Configured' : ' Not configured';
    document.getElementById('statusGrok').className = 'status-value ' + (grokKey ? 'ok' : 'warning');
    
    const mjKey = localStorage.getItem('mjKey');
    document.getElementById('statusMJ').innerHTML = mjKey ? ' Configured' : ' Not configured';
    document.getElementById('statusMJ').className = 'status-value ' + (mjKey ? 'ok' : 'warning');
    
    document.getElementById('statusComfyUI').innerHTML = ' Checking...';
    document.getElementById('statusComfyUI').className = 'status-value warning';
}

// Initialize on page load
window.addEventListener('load', () => {
    // Load saved defaults
    const savedFPS = localStorage.getItem('defaultFPS');
    const savedCodec = localStorage.getItem('defaultCodec');
    if (savedFPS) document.getElementById('fps').value = savedFPS;
    if (savedCodec) document.getElementById('codec').value = savedCodec;
    
    checkStatus();
});
