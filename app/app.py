import http.server, socketserver, socket, urllib.request, json, os
DB_PRIMARY=os.environ.get("DB_HOST","")
DB_STANDBY=os.environ.get("DB_STANDBY","")
DB_PORT=int(os.environ.get("DB_PORT","3306"))
def meta(path):
    try:
        req=urllib.request.Request("http://169.254.169.254/latest/api/token",
            headers={"X-aws-ec2-metadata-token-ttl-seconds":"60"},method="PUT")
        tok=urllib.request.urlopen(req,timeout=1).read().decode()
        req=urllib.request.Request("http://169.254.169.254/latest/meta-data/"+path,
            headers={"X-aws-ec2-metadata-token":tok})
        return urllib.request.urlopen(req,timeout=1).read().decode()
    except Exception:
        return "unknown"
def db_check():
    # Multi-AZ data tier: try the primary (AZ-a), fall back to the standby (AZ-b).
    for label,host in (("primary",DB_PRIMARY),("standby",DB_STANDBY)):
        if not host:
            continue
        try:
            s=socket.create_connection((host,DB_PORT),timeout=1); s.close()
            return (label,host,True)
        except Exception:
            continue
    return ("none","",False)
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self,*a): pass
    def do_GET(self):
        iid=meta("instance-id"); az=meta("placement/availability-zone")
        active,dbhost,up=db_check()
        if self.path.rstrip("/")=="/health":
            body=json.dumps({"status":"healthy","instance":iid,"az":az,
                "db":"up" if up else "down","db_active":active,"db_host":dbhost,
                "db_primary":DB_PRIMARY,"db_standby":DB_STANDBY}).encode()
            self.send_response(200); self.send_header("Content-Type","application/json")
            self.send_header("Content-Length",str(len(body))); self.end_headers(); self.wfile.write(body); return
        color="#12805c" if up else "#b42318"
        label=(f"Connected &middot; {active}" if up else "Unreachable")
        html=f'''<!doctype html><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1">
<title>3-Tier App</title><style>body{{font-family:-apple-system,Segoe UI,Roboto,sans-serif;background:#0f172a;color:#e2e8f0;margin:0;display:grid;place-items:center;min-height:100vh}}
.card{{background:#1e293b;border:1px solid #334155;border-radius:16px;padding:34px 40px;max-width:480px;box-shadow:0 12px 40px rgba(0,0,0,.4)}}
h1{{margin:0 0 4px;font-size:20px}}p.sub{{margin:0 0 22px;color:#94a3b8;font-size:13px}}
.row{{display:flex;justify-content:space-between;gap:20px;padding:11px 0;border-top:1px solid #334155;font-size:14px}}
.k{{color:#94a3b8}}.v{{font-family:ui-monospace,Menlo,monospace}}
.pill{{display:inline-flex;align-items:center;gap:7px;font-weight:600}}
.dot{{width:9px;height:9px;border-radius:50%;background:{color}}}</style>
<div class=card><h1>Application Tier &mdash; healthy</h1><p class=sub>Served from a private-subnet EC2 instance behind the ALB.</p>
<div class=row><span class=k>Instance ID</span><span class=v>{iid}</span></div>
<div class=row><span class=k>Availability Zone</span><span class=v>{az}</span></div>
<div class=row><span class=k>Data tier (Multi-AZ)</span><span class="v pill"><span class=dot></span>{label}</span></div>
<div class=row><span class=k>&nbsp;&nbsp;primary (AZ-a)</span><span class=v>{DB_PRIMARY}:{DB_PORT}</span></div>
<div class=row><span class=k>&nbsp;&nbsp;standby (AZ-b)</span><span class=v>{DB_STANDBY}:{DB_PORT}</span></div>
<div class=row><span class=k>Health endpoint</span><span class=v>/health</span></div></div>'''
        b=html.encode(); self.send_response(200); self.send_header("Content-Type","text/html")
        self.send_header("Content-Length",str(len(b))); self.end_headers(); self.wfile.write(b)
socketserver.TCPServer.allow_reuse_address=True
socketserver.TCPServer(("0.0.0.0",80),H).serve_forever()
