#!/bin/bash
set -e

# 启动 NapCat（调用基础镜像原始 entrypoint，后台运行）
echo "[entrypoint] 启动 NapCat..."
bash /napcat-entrypoint.sh &

# 等 NapCat HTTP 服务就绪
echo "[entrypoint] 等待 NapCat 就绪..."
for i in $(seq 1 30); do
    if curl -sf http://localhost:3000/get_login_info > /dev/null 2>&1; then
        echo "[entrypoint] NapCat 已就绪"
        break
    fi
    sleep 2
done

# 启动 FC 入口（Flask wrapper）
echo "[entrypoint] 启动 Flask wrapper，端口 $SERVER_PORT"
python3 /wrapper.py
