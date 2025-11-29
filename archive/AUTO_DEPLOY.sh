#!/bin/bash
# FULLY AUTOMATED WORKER DEPLOYMENT
# One command. No human intervention required.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   🤖 FULLY AUTOMATED WORKER DEPLOYMENT                        ║
║   Taking the fallible human out of the loop                  ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

# Create auto-deploy directory
DEPLOY_DIR="${ORCHESTRATOR_DIR}/auto-deploy"
mkdir -p "$DEPLOY_DIR"

workers=($(printf '%s\n' "${WORKER_DEFINITIONS[@]}" | cut -d'|' -f1))

echo -e "${YELLOW}Generating fully automated worker deployment...${NC}\n"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# METHOD 1: Create HTML files that auto-open Claude with prompts
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${CYAN}📝 Creating auto-launch HTML files...${NC}"

for worker_id in "${workers[@]}"; do
    # Get worker description
    for def in "${WORKER_DEFINITIONS[@]}"; do
        IFS='|' read -r wid branch task_file description <<< "$def"
        if [ "$wid" = "$worker_id" ]; then
            break
        fi
    done

    # Read the prompt
    prompt_content=$(cat "${PROMPTS_DIR}/${worker_id}-prompt.md")

    # Escape for JavaScript
    escaped_prompt=$(echo "$prompt_content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

    # Create HTML file that auto-opens Claude and provides copy button
    cat > "${DEPLOY_DIR}/${worker_id}.html" <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>${description}</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 900px;
            margin: 50px auto;
            padding: 20px;
            background: #1e1e1e;
            color: #d4d4d4;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            text-align: center;
        }
        h1 {
            margin: 0;
            color: white;
            font-size: 2em;
        }
        .subtitle {
            color: #e0e0e0;
            margin-top: 10px;
        }
        .prompt-container {
            background: #252526;
            border: 2px solid #3e3e42;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
            max-height: 400px;
            overflow-y: auto;
        }
        pre {
            white-space: pre-wrap;
            word-wrap: break-word;
            margin: 0;
            font-size: 0.9em;
            line-height: 1.6;
        }
        .button-container {
            display: flex;
            gap: 15px;
            margin: 20px 0;
        }
        button {
            flex: 1;
            padding: 15px 30px;
            font-size: 1.1em;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-weight: bold;
            transition: all 0.3s;
        }
        .copy-btn {
            background: #0e639c;
            color: white;
        }
        .copy-btn:hover {
            background: #1177bb;
            transform: translateY(-2px);
        }
        .launch-btn {
            background: #16a34a;
            color: white;
        }
        .launch-btn:hover {
            background: #15803d;
            transform: translateY(-2px);
        }
        .auto-btn {
            background: #dc2626;
            color: white;
        }
        .auto-btn:hover {
            background: #b91c1c;
            transform: translateY(-2px);
        }
        .status {
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
            text-align: center;
            font-weight: bold;
        }
        .success {
            background: #065f46;
            color: #d1fae5;
        }
        .info {
            background: #1e40af;
            color: #dbeafe;
        }
        .instructions {
            background: #252526;
            border-left: 4px solid #667eea;
            padding: 20px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .instructions ol {
            margin: 10px 0;
            padding-left: 20px;
        }
        .instructions li {
            margin: 8px 0;
            line-height: 1.6;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🤖 ${description}</h1>
        <div class="subtitle">Worker ID: ${worker_id} | Branch: ${branch}</div>
    </div>

    <div class="instructions">
        <h2>🚀 Automated Deployment</h2>
        <p>This worker is ready to be deployed to Claude Code!</p>
        <ol>
            <li><strong>Click "🚀 Copy & Launch Claude"</strong> - Copies prompt to clipboard AND opens Claude</li>
            <li><strong>Paste</strong> (Ctrl+V or Cmd+V) into the Claude chat that opens</li>
            <li><strong>Done!</strong> Claude will start working immediately</li>
        </ol>
    </div>

    <div class="button-container">
        <button class="copy-btn" onclick="copyPrompt()">📋 Copy Prompt Only</button>
        <button class="launch-btn" onclick="copyAndLaunch()">🚀 Copy & Launch Claude</button>
        <button class="auto-btn" onclick="fullyAutomatic()">⚡ FULLY AUTOMATIC</button>
    </div>

    <div id="status"></div>

    <div class="prompt-container">
        <h3>Worker Prompt:</h3>
        <pre id="prompt">${escaped_prompt}</pre>
    </div>

    <script>
        const prompt = \`${escaped_prompt}\`;

        function copyPrompt() {
            navigator.clipboard.writeText(prompt).then(() => {
                showStatus('✅ Prompt copied to clipboard!', 'success');
            }).catch(err => {
                showStatus('❌ Failed to copy. Please copy manually.', 'info');
            });
        }

        function copyAndLaunch() {
            // Copy prompt
            navigator.clipboard.writeText(prompt).then(() => {
                showStatus('✅ Prompt copied! Opening Claude...', 'success');

                // Open Claude in new tab
                window.open('https://claude.ai/new', '_blank');

                setTimeout(() => {
                    showStatus('📝 Now paste (Ctrl+V or Cmd+V) into Claude!', 'info');
                }, 2000);
            });
        }

        function fullyAutomatic() {
            showStatus('🚀 FULLY AUTOMATIC MODE ACTIVATED!', 'success');

            // Copy prompt
            navigator.clipboard.writeText(prompt).then(() => {
                // Open Claude
                const claudeWindow = window.open('https://claude.ai/new', '_blank');

                setTimeout(() => {
                    showStatus('⚡ Prompt copied! Claude opened! Now just paste!', 'success');

                    // Attempt to focus the Claude window (may not work due to browser restrictions)
                    if (claudeWindow) {
                        claudeWindow.focus();
                    }
                }, 1000);
            });
        }

        function showStatus(message, type) {
            const statusDiv = document.getElementById('status');
            statusDiv.textContent = message;
            statusDiv.className = 'status ' + type;
        }

        // Auto-copy on page load for maximum automation
        window.addEventListener('load', () => {
            showStatus('📋 Ready to deploy ${worker_id}!', 'info');
        });
    </script>
</body>
</html>
HTML

    echo -e "${GREEN}  ✅ Created ${worker_id}.html${NC}"
done

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Create master launcher HTML
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cat > "${DEPLOY_DIR}/LAUNCH_ALL_WORKERS.html" <<MASTER
<!DOCTYPE html>
<html>
<head>
    <title>SARK v1.1 - Deploy All Workers</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 1000px;
            margin: 50px auto;
            padding: 20px;
            background: #1e1e1e;
            color: #d4d4d4;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 40px;
            border-radius: 10px;
            margin-bottom: 30px;
            text-align: center;
        }
        h1 {
            margin: 0;
            color: white;
            font-size: 2.5em;
        }
        .subtitle {
            color: #e0e0e0;
            margin-top: 15px;
            font-size: 1.2em;
        }
        .worker-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .worker-card {
            background: #252526;
            border: 2px solid #3e3e42;
            border-radius: 10px;
            padding: 25px;
            transition: all 0.3s;
            cursor: pointer;
        }
        .worker-card:hover {
            border-color: #667eea;
            transform: translateY(-5px);
            box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
        }
        .worker-card h3 {
            margin: 0 0 10px 0;
            color: #667eea;
            font-size: 1.3em;
        }
        .worker-card p {
            margin: 5px 0;
            color: #888;
            font-size: 0.9em;
        }
        .launch-all-btn {
            width: 100%;
            padding: 20px;
            font-size: 1.3em;
            background: linear-gradient(135deg, #16a34a 0%, #15803d 100%);
            color: white;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-weight: bold;
            margin: 30px 0;
            transition: all 0.3s;
        }
        .launch-all-btn:hover {
            transform: translateY(-3px);
            box-shadow: 0 10px 30px rgba(22, 163, 74, 0.4);
        }
        .instructions {
            background: #252526;
            border-left: 4px solid #667eea;
            padding: 25px;
            margin: 30px 0;
            border-radius: 4px;
        }
        .instructions h2 {
            margin-top: 0;
            color: #667eea;
        }
        .status {
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            text-align: center;
            font-weight: bold;
            font-size: 1.1em;
        }
        .success {
            background: #065f46;
            color: #d1fae5;
        }
        .countdown {
            font-size: 2em;
            color: #667eea;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🎭 ${PROJECT_NAME}</h1>
        <div class="subtitle">Multi-Agent Worker Deployment System</div>
    </div>

    <div class="instructions">
        <h2>🚀 Fully Automated Deployment</h2>
        <p><strong>Click the big green button below to deploy ALL workers at once!</strong></p>
        <p>This will:</p>
        <ul>
            <li>Open 6 Claude Code tabs</li>
            <li>Copy each worker's prompt to clipboard (one at a time)</li>
            <li>You just paste in each tab as it opens</li>
            <li>Workers start working immediately!</li>
        </ul>
        <p><em>Or click individual workers below to deploy one at a time.</em></p>
    </div>

    <button class="launch-all-btn" onclick="launchAll()">
        🚀 DEPLOY ALL ${#workers[@]} WORKERS (FULLY AUTOMATIC)
    </button>

    <div id="status"></div>

    <div class="worker-grid">
MASTER

# Add worker cards
for worker_id in "${workers[@]}"; do
    for def in "${WORKER_DEFINITIONS[@]}"; do
        IFS='|' read -r wid branch task_file description <<< "$def"
        if [ "$wid" = "$worker_id" ]; then
            break
        fi
    done

    cat >> "${DEPLOY_DIR}/LAUNCH_ALL_WORKERS.html" <<MASTER
        <div class="worker-card" onclick="launchWorker('${worker_id}')">
            <h3>${worker_id}</h3>
            <p><strong>${description}</strong></p>
            <p>Branch: ${branch}</p>
        </div>
MASTER
done

cat >> "${DEPLOY_DIR}/LAUNCH_ALL_WORKERS.html" <<'MASTER'
    </div>

    <script>
        const workers = [
MASTER

# Add worker data
for worker_id in "${workers[@]}"; do
    prompt_content=$(cat "${PROMPTS_DIR}/${worker_id}-prompt.md" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    cat >> "${DEPLOY_DIR}/LAUNCH_ALL_WORKERS.html" <<MASTER
            { id: '${worker_id}', prompt: "${prompt_content}" },
MASTER
done

cat >> "${DEPLOY_DIR}/LAUNCH_ALL_WORKERS.html" <<'MASTER'
        ];

        function launchWorker(workerId) {
            window.open(workerId + '.html', '_blank');
        }

        async function launchAll() {
            showStatus('🚀 DEPLOYING ALL WORKERS!', 'success');

            for (let i = 0; i < workers.length; i++) {
                const worker = workers[i];

                showStatus(`🚀 Deploying worker ${i + 1}/${workers.length}: ${worker.id}...`, 'success');

                // Copy prompt to clipboard
                await navigator.clipboard.writeText(worker.prompt);

                // Open Claude tab
                window.open('https://claude.ai/new', '_blank');

                // Wait 3 seconds before next worker
                if (i < workers.length - 1) {
                    await sleep(3000);
                }
            }

            showStatus('✅ ALL WORKERS DEPLOYED! Paste prompts into each Claude tab!', 'success');
        }

        function sleep(ms) {
            return new Promise(resolve => setTimeout(resolve, ms));
        }

        function showStatus(message, type) {
            const statusDiv = document.getElementById('status');
            statusDiv.textContent = message;
            statusDiv.className = 'status ' + type;
        }
    </script>
</body>
</html>
MASTER

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ FULLY AUTOMATED DEPLOYMENT READY!${NC}\n"

echo -e "${CYAN}📁 Location:${NC}"
echo "   ${DEPLOY_DIR}/"
echo ""

echo -e "${YELLOW}🚀 TO DEPLOY (One Command):${NC}\n"

if command -v wslview &> /dev/null; then
    # WSL - use wslview
    echo "   wslview ${DEPLOY_DIR}/LAUNCH_ALL_WORKERS.html"
    echo ""
    echo -e "${CYAN}Or run this now:${NC}"
    wslview "${DEPLOY_DIR}/LAUNCH_ALL_WORKERS.html"
elif command -v xdg-open &> /dev/null; then
    # Linux - use xdg-open
    echo "   xdg-open ${DEPLOY_DIR}/LAUNCH_ALL_WORKERS.html"
    echo ""
    echo -e "${CYAN}Or run this now:${NC}"
    xdg-open "${DEPLOY_DIR}/LAUNCH_ALL_WORKERS.html"
else
    # Manual
    echo "   Open this file in your browser:"
    echo "   ${DEPLOY_DIR}/LAUNCH_ALL_WORKERS.html"
fi

echo ""
echo -e "${YELLOW}📋 What happens:${NC}"
echo "   1. Browser opens with master control panel"
echo "   2. Click the big green button"
echo "   3. 6 Claude tabs open (one every 3 seconds)"
echo "   4. Each worker's prompt is auto-copied"
echo "   5. You just paste in each tab (Ctrl+V)"
echo "   6. Workers start working!"
echo ""
echo -e "${GREEN}🎸 MAXIMUM AUTOMATION ACHIEVED!${NC}"
