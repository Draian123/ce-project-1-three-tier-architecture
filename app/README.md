# Application

Dependency-light web app for the application tier — **Python standard library only** (no `pip install`), so it runs on a stock Amazon Linux 2023 image with no internet fetch at boot.

## Files
- **`app.py`** — the web server (single source of truth). Serves `/` (HTML status page) and `/health` (JSON). Reports instance-id and AZ from IMDSv2 and checks data-tier reachability via a TCP connect to `DB_HOST:DB_PORT`.
- **`deploy.sh`** — one-shot deploy of the data tier, the 3 app instances, and the ALB/target group. Embeds `app.py` into the app user-data and injects the data instance's IP as `DB_HOST` at launch. Assumes the network + security groups already exist (IDs pre-filled at the top, overridable via env vars).
- **`package.json`** — project manifest / metadata. The runtime is Python 3 (stdlib only); `npm run deploy` wraps `deploy.sh`.

## Configuration
`app.py` reads two environment variables (set by `webapp.service`):
- `DB_HOST` — private IP of the data-tier instance (e.g. `10.0.21.110`)
- `DB_PORT` — default `3306`

## Endpoints
| Path | Response |
|---|---|
| `/` | HTML page: instance-id, AZ, data-tier connection status |
| `/health` | `{"status":"healthy","instance":"i-…","az":"us-east-1a","db":"up","db_host":"10.0.21.110"}` |

The ALB target group health check polls `/health` and expects HTTP 200.
