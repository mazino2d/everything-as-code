#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y fortune-mod cowsay python3

cat > /opt/fortune_server.py << 'PYEOF'
#!/usr/bin/env python3
import http.server
import subprocess
import socketserver

PORT = 80

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        fortune = subprocess.check_output(["/usr/games/fortune"]).decode()
        art = subprocess.run(
            ["/usr/games/cowsay", fortune], capture_output=True, text=True
        ).stdout
        html = f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="8">
  <title>fortune</title>
  <style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{
      background: #0d0d0d;
      color: #39ff14;
      font-family: monospace;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      gap: 2rem;
    }}
    pre {{ font-size: 1.1rem; line-height: 1.5; }}
    .hint {{ color: #555; font-size: 0.8rem; }}
  </style>
</head>
<body>
  <pre>{art}</pre>
  <span class="hint">refreshes every 8s</span>
</body>
</html>""".encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(html)))
        self.end_headers()
        self.wfile.write(html)

    def log_message(self, *args):
        pass

with socketserver.TCPServer(("", PORT), Handler) as s:
    s.serve_forever()
PYEOF

cat > /etc/systemd/system/fortune-server.service << 'EOF'
[Unit]
Description=Fortune Cookie Web Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/fortune_server.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable fortune-server
systemctl start fortune-server
