#!/bin/bash
# CLI-Based Worker Deployment
# Uses Claude API directly via CLI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   🤖 CLI-BASED WORKER DEPLOYMENT                              ║
║   Direct API integration - No human required                 ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

# Check for API key
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo -e "${YELLOW}⚠️  ANTHROPIC_API_KEY not set${NC}\n"
    echo "To use CLI deployment, you need an Anthropic API key."
    echo ""
    echo "Options:"
    echo "1. Set environment variable: export ANTHROPIC_API_KEY='your-key'"
    echo "2. Create .env file in orchestrator directory"
    echo "3. Use alternative deployment method (./AUTO_DEPLOY.sh)"
    echo ""
    read -p "Do you have an API key? (y/N): " has_key

    if [[ "$has_key" =~ ^[Yy]$ ]]; then
        read -p "Enter your Anthropic API key: " api_key
        export ANTHROPIC_API_KEY="$api_key"

        # Save to .env
        echo "ANTHROPIC_API_KEY=$api_key" > "${ORCHESTRATOR_DIR}/.env"
        echo -e "${GREEN}✅ API key saved to .env${NC}\n"
    else
        echo -e "${YELLOW}Using alternative deployment method...${NC}\n"
        exec "${ORCHESTRATOR_DIR}/AUTO_DEPLOY.sh"
    fi
fi

# Create working directory
CLI_DIR="${ORCHESTRATOR_DIR}/cli-workers"
mkdir -p "$CLI_DIR"

workers=($(printf '%s\n' "${WORKER_DEFINITIONS[@]}" | cut -d'|' -f1))

echo -e "${YELLOW}Deployment Method:${NC}\n"
echo "1. tmux sessions (each worker in own tmux, calling Claude API)"
echo "2. Background processes (workers run as background jobs)"
echo "3. Sequential (workers run one after another)"
echo ""
read -p "Choose method (1-3): " method
echo ""

case $method in
    1)
        echo -e "${CYAN}🚀 Deploying workers in tmux sessions...${NC}\n"

        for worker_id in "${workers[@]}"; do
            echo -e "${GREEN}Launching ${worker_id} in tmux...${NC}"

            # Get worker details
            for def in "${WORKER_DEFINITIONS[@]}"; do
                IFS='|' read -r wid branch task_file description <<< "$def"
                if [ "$wid" = "$worker_id" ]; then
                    break
                fi
            done

            # Kill existing session if present
            tmux kill-session -t "sark-cli-${worker_id}" 2>/dev/null || true

            # Create tmux session with CLI worker
            tmux new-session -d -s "sark-cli-${worker_id}" -c "$PROJECT_ROOT"

            # Create worker script
            cat > "${CLI_DIR}/${worker_id}-worker.sh" <<WORKER
#!/bin/bash
set -euo pipefail

export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"

echo "╔═══════════════════════════════════════════════════════╗"
echo "║  🤖 CLI Worker: ${worker_id}                          "
echo "║  ${description}"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

cd ${PROJECT_ROOT}

# Read the prompt
PROMPT=\$(cat ${PROMPTS_DIR}/${worker_id}-prompt.md)

echo "📋 Task loaded. Sending to Claude API..."
echo ""

# Create conversation log
LOG_FILE="${CLI_DIR}/${worker_id}-conversation.log"

# Send initial prompt to Claude API
response=\$(curl -s https://api.anthropic.com/v1/messages \\
  -H "content-type: application/json" \\
  -H "x-api-key: \${ANTHROPIC_API_KEY}" \\
  -H "anthropic-version: 2023-06-01" \\
  -d "{
    \"model\": \"claude-3-5-sonnet-20241022\",
    \"max_tokens\": 8192,
    \"messages\": [{
      \"role\": \"user\",
      \"content\": \"\$PROMPT\"
    }]
  }")

echo "✅ Response received!"
echo ""

# Extract response text
response_text=\$(echo "\$response" | jq -r '.content[0].text')

echo "━━━ Claude's Response ━━━"
echo "\$response_text"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Log conversation
{
  echo "=== ${worker_id} Conversation Log ==="
  echo "Date: \$(date)"
  echo ""
  echo "=== Prompt ==="
  echo "\$PROMPT"
  echo ""
  echo "=== Response ==="
  echo "\$response_text"
  echo ""
} >> "\$LOG_FILE"

echo "📝 Conversation logged to: \$LOG_FILE"
echo ""
echo "🔄 Worker is now in interactive mode."
echo "   Attach to this tmux session to continue the conversation."
echo "   tmux attach -t sark-cli-${worker_id}"
echo ""
echo "Press Ctrl+C to stop, or Ctrl+B D to detach."

# Keep session alive
exec bash
WORKER

            chmod +x "${CLI_DIR}/${worker_id}-worker.sh"

            # Run worker script in tmux
            tmux send-keys -t "sark-cli-${worker_id}" "${CLI_DIR}/${worker_id}-worker.sh" C-m

            echo -e "${GREEN}  ✅ ${worker_id} launched in tmux session: sark-cli-${worker_id}${NC}"
        done

        echo ""
        echo -e "${GREEN}✅ All workers deployed!${NC}\n"
        echo -e "${YELLOW}View workers:${NC}"
        echo "  tmux ls | grep sark-cli"
        echo ""
        echo -e "${YELLOW}Attach to a worker:${NC}"
        echo "  tmux attach -t sark-cli-engineer1"
        echo ""
        echo -e "${YELLOW}View conversation logs:${NC}"
        echo "  cat ${CLI_DIR}/*-conversation.log"
        ;;

    2)
        echo -e "${CYAN}🚀 Deploying workers as background processes...${NC}\n"

        for worker_id in "${workers[@]}"; do
            echo -e "${GREEN}Starting ${worker_id} in background...${NC}"

            # Get worker details
            for def in "${WORKER_DEFINITIONS[@]}"; do
                IFS='|' read -r wid branch task_file description <<< "$def"
                if [ "$wid" = "$worker_id" ]; then
                    break
                fi
            done

            # Create worker script (same as above)
            cat > "${CLI_DIR}/${worker_id}-worker.sh" <<'WORKER'
#!/bin/bash
set -euo pipefail

WORKER_ID="$1"
DESCRIPTION="$2"
PROMPT_FILE="$3"
PROJECT_ROOT="$4"
CLI_DIR="$5"

export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"

cd "$PROJECT_ROOT"

PROMPT=$(cat "$PROMPT_FILE")
LOG_FILE="${CLI_DIR}/${WORKER_ID}-conversation.log"
PID_FILE="${CLI_DIR}/${WORKER_ID}.pid"

echo $$ > "$PID_FILE"

{
  echo "╔═══════════════════════════════════════════════════════╗"
  echo "║  🤖 CLI Worker: ${WORKER_ID}"
  echo "║  ${DESCRIPTION}"
  echo "╚═══════════════════════════════════════════════════════╝"
  echo ""
  echo "📋 Sending task to Claude API..."

  response=$(curl -s https://api.anthropic.com/v1/messages \
    -H "content-type: application/json" \
    -H "x-api-key: ${ANTHROPIC_API_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -d "{
      \"model\": \"claude-3-5-sonnet-20241022\",
      \"max_tokens\": 8192,
      \"messages\": [{
        \"role\": \"user\",
        \"content\": $(echo "$PROMPT" | jq -Rs .)
      }]
    }")

  response_text=$(echo "$response" | jq -r '.content[0].text')

  echo "=== ${WORKER_ID} Conversation Log ==="
  echo "Date: $(date)"
  echo ""
  echo "=== Prompt ==="
  echo "$PROMPT"
  echo ""
  echo "=== Response ==="
  echo "$response_text"
  echo ""

} >> "$LOG_FILE" 2>&1

rm "$PID_FILE"
WORKER

            chmod +x "${CLI_DIR}/${worker_id}-worker.sh"

            # Run in background
            "${CLI_DIR}/${worker_id}-worker.sh" \
                "$worker_id" \
                "$description" \
                "${PROMPTS_DIR}/${worker_id}-prompt.md" \
                "$PROJECT_ROOT" \
                "$CLI_DIR" &

            echo -e "${GREEN}  ✅ ${worker_id} started (PID: $!)${NC}"
        done

        echo ""
        echo -e "${GREEN}✅ All workers running in background!${NC}\n"
        echo -e "${YELLOW}Monitor progress:${NC}"
        echo "  tail -f ${CLI_DIR}/*-conversation.log"
        echo ""
        echo -e "${YELLOW}Check if workers are running:${NC}"
        echo "  ls ${CLI_DIR}/*.pid"
        ;;

    3)
        echo -e "${CYAN}🚀 Deploying workers sequentially...${NC}\n"

        for worker_id in "${workers[@]}"; do
            echo -e "${GREEN}━━━ Starting ${worker_id} ━━━${NC}"

            # Get worker details
            for def in "${WORKER_DEFINITIONS[@]}"; do
                IFS='|' read -r wid branch task_file description <<< "$def"
                if [ "$wid" = "$worker_id" ]; then
                    break
                fi
            done

            PROMPT=$(cat "${PROMPTS_DIR}/${worker_id}-prompt.md")

            echo "Sending to Claude API..."

            response=$(curl -s https://api.anthropic.com/v1/messages \
              -H "content-type: application/json" \
              -H "x-api-key: ${ANTHROPIC_API_KEY}" \
              -H "anthropic-version: 2023-06-01" \
              -d "{
                \"model\": \"claude-3-5-sonnet-20241022\",
                \"max_tokens\": 8192,
                \"messages\": [{
                  \"role\": \"user\",
                  \"content\": $(echo "$PROMPT" | jq -Rs .)
                }]
              }")

            response_text=$(echo "$response" | jq -r '.content[0].text')

            echo ""
            echo "━━━ Response ━━━"
            echo "$response_text"
            echo ""

            # Save to log
            {
              echo "=== ${worker_id} ==="
              echo "Date: $(date)"
              echo "$response_text"
              echo ""
            } >> "${CLI_DIR}/all-workers.log"

            echo -e "${GREEN}✅ ${worker_id} complete${NC}\n"
        done

        echo -e "${GREEN}✅ All workers complete!${NC}"
        echo "Log: ${CLI_DIR}/all-workers.log"
        ;;
esac

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📊 Monitor overall progress:${NC}"
echo "  cd ${ORCHESTRATOR_DIR}"
echo "  ./dashboard.py"
echo ""
echo -e "${YELLOW}🎸 Workers are now autonomous!${NC}"
