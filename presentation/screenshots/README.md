# Demo Screenshots (backup evidence)

These are the fallback visuals for the live demo — if the network misbehaves on presentation day, show these instead and narrate them.

## Captured
- **`app-load-balancing.gif`** — the live app at the ALB URL, refreshed across page loads showing the **Instance ID and AZ changing** (`i-006dcbf0…`/us-east-1a → `i-098084ed…`/us-east-1b → `i-0375a3d0…`/us-east-1a). Direct proof the ALB distributes traffic across all three instances in both AZs, with the data tier showing **Connected** every time.

Verified live during prep (both endpoints returned 200):
- `GET /` → status page (instance-id, AZ, "Data tier: Connected")
- `GET /health` → `{"status":"healthy","instance":"i-006dcbf0b26c73872","az":"us-east-1a","db":"up","db_host":"10.0.21.110"}`

## Shot list — capture these from YOUR console before the presentation
Take these in the AWS console (us-east-1) so the backup set is complete and account-specific:

| File to save | Where | Should clearly show |
|---|---|---|
| `01-app-home.png` | `http://<ALB-DNS>/` | The app status page (instance-id, AZ, Connected) |
| `02-health-json.png` | `http://<ALB-DNS>/health` | The JSON health response |
| `03-target-health.png` | EC2 → Target Groups → `ce-app-tg` → Targets | **3/3 healthy** across two AZs |
| `04-instances.png` | EC2 → Instances (filter tag `Project=ce-project-1`) | 4 instances; app/data with **no public IPv4** |
| `05-security-groups.png` | EC2 → Security Groups | The 3 tier SGs and their inbound rules (SG-to-SG) |
| `06-vpc-subnets.png` | VPC → Subnets | 6 subnets across 2 AZs |
| `07-route-tables.png` | VPC → Route tables → `data-rt` | Data route table with **only the local route** (no 0.0.0.0/0) |
| `08-load-balancer.png` | EC2 → Load Balancers → `ce-app-alb` | Internet-facing, active, 2 AZs |

**Tip:** on Windows use `Win+Shift+S` (Snipping Tool) to grab a region and save straight into this folder.
