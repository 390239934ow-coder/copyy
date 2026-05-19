import os
import requests
from flask import Flask, request, jsonify

app = Flask(__name__)
NAPCAT = "http://localhost:3000"
QQ_GROUP = int(os.environ.get("QQ_GROUP_ID", "0"))


@app.get("/")
def health():
    try:
        r = requests.get(f"{NAPCAT}/get_login_info", timeout=3)
        return jsonify({"ok": True, "login": r.json()})
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)}), 503


@app.post("/send")
def send():
    data = request.json or {}
    group = data.get("group_id", QQ_GROUP)
    message = data.get("message", "")
    if not message:
        return jsonify({"error": "message is required"}), 400
    try:
        r = requests.post(f"{NAPCAT}/send_group_msg", json={
            "group_id": group,
            "message": message,
        }, timeout=10)
        return jsonify(r.json())
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    port = int(os.environ.get("SERVER_PORT", 9000))
    app.run(host="0.0.0.0", port=port)
