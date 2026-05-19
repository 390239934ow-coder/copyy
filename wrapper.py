"""
FC QQ Bot wrapper
- 监听 FC_SERVER_PORT（FC 要求）
- 代理到本地 NapCat HTTP Server（port 3000）
- 同时暴露 NapCat 登录页（/login）供首次扫码
"""

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
    """merchant-fetcher 调用此接口发群消息"""
    data    = request.json or {}
    group   = data.get("group_id", QQ_GROUP)
    message = data.get("message", "")
    if not message:
        return jsonify({"error": "message is required"}), 400
    try:
        r = requests.post(f"{NAPCAT}/send_group_msg", json={
            "group_id": group,
            "message":  message,
        }, timeout=10)
        return jsonify(r.json())
    except Exception as e:
        return jsonify({"error": str(e)}), 500


NAPCAT_UI = "http://localhost:6099"

@app.route("/login", defaults={"path": ""})
@app.route("/login/<path:path>")
def login(path):
    """首次登录：反代 NapCat WebUI（port 6099）"""
    url = f"{NAPCAT_UI}/{path}"
    try:
        resp = requests.request(
            method  = request.method,
            url     = url,
            headers = {k: v for k, v in request.headers if k.lower() != "host"},
            data    = request.get_data(),
            params  = request.args,
            allow_redirects = False,
            timeout = 10,
        )
        headers = dict(resp.headers)
        # 去掉会导致 Flask 二次编码冲突的头
        for h in ["Transfer-Encoding", "Content-Encoding", "Content-Length"]:
            headers.pop(h, None)
        if "Location" in headers and headers["Location"].startswith("/"):
            headers["Location"] = "/login" + headers["Location"]
        return resp.content, resp.status_code, headers
    except Exception as e:
        return jsonify({"error": str(e)}), 502


if __name__ == "__main__":
    port = int(os.environ.get("SERVER_PORT", 9000))
    app.run(host="0.0.0.0", port=port)
