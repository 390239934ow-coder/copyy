#!/bin/bash
set -e

# 1. 将 NapCat 配置目录持久化到 NAS（/app/.config/QQ 已挂载 NAS）
NAPCAT_CONFIG_NAS="/app/.config/QQ/napcat_config"
mkdir -p "$NAPCAT_CONFIG_NAS"
if [ ! -L /app/napcat/config ]; then
    rm -rf /app/napcat/config
    ln -s "$NAPCAT_CONFIG_NAS" /app/napcat/config
    echo "[entrypoint] NapCat 配置目录已链接到 NAS: $NAPCAT_CONFIG_NAS"
else
    echo "[entrypoint] NapCat 配置目录已是 NAS 链接"
fi

# 2. 预写 HTTP 服务器配置（如尚未配置）
if [ -n "$ACCOUNT" ]; then
    CONFIG_FILE="/app/napcat/config/onebot11_${ACCOUNT}.json"
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << 'EOF'
{
  "httpServers": [
    {
      "name": "http-api",
      "enable": true,
      "port": 3000,
      "host": "0.0.0.0",
      "enableHeart": false,
      "heartInterval": 30000,
      "token": "",
      "debug": false,
      "messagePostFormat": "array",
      "reportSelfMessage": false
    }
  ],
  "httpClients": [],
  "websocketServers": [],
  "websocketClients": []
}
EOF
        echo "[entrypoint] 已预配置 NapCat HTTP 服务器 (port 3000) → $CONFIG_FILE"
    else
        echo "[entrypoint] NapCat HTTP 服务器配置已存在，跳过"
    fi
else
    echo "[entrypoint] 警告: ACCOUNT 未设置，无法预配置 HTTP 服务器"
fi

# 3. 启动 NapCat（调用基础镜像原始 entrypoint，后台运行）
echo "[entrypoint] 启动 NapCat..."
bash /app/napcat-entrypoint.sh &

# 4. 等 NapCat WebUI 就绪（比等 port 3000 更快）
echo "[entrypoint] 等待 NapCat 就绪..."
for i in $(seq 1 20); do
    if curl -sf http://localhost:6099/ > /dev/null 2>&1; then
        echo "[entrypoint] NapCat 已就绪"
        break
    fi
    sleep 2
done

# 5. 启动 FC 入口（Flask wrapper）
echo "[entrypoint] 启动 Flask wrapper，端口 $SERVER_PORT"
python3 /wrapper.py
