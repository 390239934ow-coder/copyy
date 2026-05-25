#!/bin/bash

# === 0. Ensure directories exist ===
mkdir -p /app/.config /app/napcat /mnt/qq-bot

# === 1. NAS → /app/.config/QQ ===
if [ ! -L /app/.config/QQ ]; then
    rm -rf /app/.config/QQ
    ln -s /mnt/qq-bot /app/.config/QQ
fi

# === 2. NapCat config → NAS ===
NAPCAT_CONFIG="/mnt/qq-bot/napcat_config"
mkdir -p "$NAPCAT_CONFIG"
if [ ! -L /app/napcat/config ]; then
    rm -rf /app/napcat/config
    ln -s "$NAPCAT_CONFIG" /app/napcat/config
fi

# === 3. OneBot11 HTTP Server config (always overwrite) ===
if [ -n "$ACCOUNT" ]; then
    cat > "$NAPCAT_CONFIG/onebot11_${ACCOUNT}.json" << 'EOF'
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
  "websocketClients": [],
  "network": {
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
}
EOF
fi

# === 4. Start NapCat (base image entrypoint, background) ===
bash /app/napcat-entrypoint.sh &

# === 5. Wait for NapCat FULLY ready (group list must work) ===
for i in $(seq 1 60); do
    if curl -sf http://localhost:3000/get_group_list > /dev/null 2>&1; then
        break
    fi
    sleep 2
done

# === 6. Start Flask API (FC entrypoint, foreground) ===
exec python3 /wrapper.py
