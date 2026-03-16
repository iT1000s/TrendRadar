#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# TrendRadar 一键部署脚本（香港 VPS）
# 使用方式：
#   1. 将此脚本上传到 VPS
#   2. chmod +x deploy.sh
#   3. ./deploy.sh
# ═══════════════════════════════════════════════════════════════

set -e

echo "═══════════════════════════════════════════════════"
echo "  TrendRadar 一键部署"
echo "═══════════════════════════════════════════════════"

# ─── 1. 检查 Docker ───
if ! command -v docker &> /dev/null; then
    echo "[1/5] 安装 Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo "✅ Docker 安装完成"
else
    echo "[1/5] ✅ Docker 已安装"
fi

if ! command -v docker compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "⚠️  请确保 Docker Compose V2 已安装（docker compose 命令）"
    exit 1
fi

# ─── 2. 克隆/更新仓库 ───
INSTALL_DIR="$HOME/TrendRadar"

if [ -d "$INSTALL_DIR" ]; then
    echo "[2/5] 更新仓库..."
    cd "$INSTALL_DIR"
    git pull origin master
else
    echo "[2/5] 克隆仓库..."
    git clone https://github.com/iT1000s/TrendRadar.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi
echo "✅ 仓库就绪"

# ─── 3. 配置环境变量 ───
ENV_FILE="$INSTALL_DIR/docker/.env.local"

if [ ! -f "$ENV_FILE" ]; then
    echo "[3/5] 创建环境配置..."
    cat > "$ENV_FILE" << 'ENVEOF'
# ═══════════════════════════════════════════════════
# TrendRadar 环境变量配置
# ═══════════════════════════════════════════════════

# ──── AI 配置（必填）────
# 方式一：xAI 直连（推荐）
AI_MODEL=xai/grok-4.1-fast
AI_API_KEY=你的_API_Key
AI_API_BASE=

# 方式二：OpenRouter（取消注释并替换上面的值）
# AI_MODEL=openai/x-ai/grok-4.1-fast
# AI_API_KEY=你的_OpenRouter_Key
# AI_API_BASE=https://openrouter.ai/api/v1

# 方式三：OpenAI 直连
# AI_MODEL=openai/gpt-4o
# AI_API_KEY=sk-xxx
# AI_API_BASE=

# ──── 推送渠道（至少配一个）────
FEISHU_WEBHOOK_URL=
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=
DINGTALK_WEBHOOK_URL=

# ──── 运行配置 ────
# 每30分钟抓取一次
CRON_SCHEDULE="*/30 * * * *"
RUN_MODE=cron
IMMEDIATE_RUN=true

# Web 报告服务器（浏览器访问 http://VPS_IP:8080）
ENABLE_WEBSERVER=true
WEBSERVER_PORT=8080

# ──── 以下一般不用改 ────
AI_ANALYSIS_ENABLED=true
ENVEOF

    echo ""
    echo "⚠️  请编辑环境配置文件，填入你的 API Key 和推送 Webhook："
    echo "    nano $ENV_FILE"
    echo ""
    echo "填完后重新运行此脚本即可启动。"
    exit 0
else
    echo "[3/5] ✅ 环境配置已存在"
fi

# ─── 4. 检查必要配置 ───
source "$ENV_FILE"
if [ "$AI_API_KEY" = "你的_API_Key" ] || [ -z "$AI_API_KEY" ]; then
    echo "❌ 请先编辑 $ENV_FILE 填入 AI_API_KEY"
    echo "   nano $ENV_FILE"
    exit 1
fi

if [ -z "$FEISHU_WEBHOOK_URL" ] && [ -z "$TELEGRAM_BOT_TOKEN" ] && [ -z "$DINGTALK_WEBHOOK_URL" ]; then
    echo "⚠️  警告：未配置任何推送渠道，将只生成本地报告"
fi
echo "[4/5] ✅ 配置检查通过"

# ─── 5. 启动服务 ───
echo "[5/5] 启动 TrendRadar..."
cd "$INSTALL_DIR/docker"
docker compose --env-file .env.local pull
docker compose --env-file .env.local up -d

echo ""
echo "═══════════════════════════════════════════════════"
echo "  ✅ TrendRadar 部署完成！"
echo "═══════════════════════════════════════════════════"
echo ""
echo "  📊 Web 报告:  http://$(hostname -I | awk '{print $1}'):8080"
echo "  📁 数据目录:  $INSTALL_DIR/output/"
echo "  📝 查看日志:  docker logs -f trendradar"
echo "  🔄 更新重启:  cd $INSTALL_DIR && git pull && cd docker && docker compose --env-file .env.local pull && docker compose --env-file .env.local up -d"
echo "  🛑 停止服务:  cd $INSTALL_DIR/docker && docker compose --env-file .env.local down"
echo ""
