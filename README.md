# CE Project 1 — 3-Tier Cloud Architecture

A production-shaped **3-tier web application** on AWS: an internet-facing Application Load Balancer distributes traffic across a stateless, multi-AZ fleet of EC2 web servers, backed by an isolated data tier. Built in `us-east-1` inside a single VPC spanning two Availability Zones.

**Author:** Dennis (individual project)
**Live endpoint:** http://ce-app-alb-1960431634.us-east-1.elb.amazonaws.com
**Interactive diagram:** [`architecture/architecture-diagram.html`](architecture/architecture-diagram.html)

---

## Architecture at a glance

```
                         Internet
                            │  HTTP :80
                    ┌───────▼────────┐
                    │ Internet GW    │
                    └───────┬────────┘
              ┌─────────────▼──────────────┐   Presentation tier (public subnets)
              │   Application Load Balancer │   spans us-east-1a + us-east-1b
              └─────────────┬──────────────┘
                 forward → target group (/health)
        ┌─────────────┬─────┴───────┬─────────────┐   Application tier (private subnets)
        ▼             ▼             ▼                   3× EC2, no public IP
   app-web-1a     app-web-1a     app-web-1b            App SG ⟵ ALB SG :80
        └─────────────┴──────┬──────┴─────────────┘
                             ▼  TCP :3306                Data tier (isolated subnet)
                        data-db-1a                       Data SG ⟵ App SG, no internet route
```

| Tier | Resources | Network |
|---|---|---|
| **1 · Presentation** | ALB `ce-app-alb` (internet-facing, HTTP :80) | public subnets, `public-rt` → IGW |
| **2 · Application** | 3× EC2 t3.micro (AL2023), stateless Python app | private subnets, `app-rt` → NAT (outbound only) |
| **3 · Data** | 1× EC2 simulated DB (:3306) | isolated subnets, `data-rt` → local only |

Full detail in **[ARCHITECTURE.md](ARCHITECTURE.md)**.

## Key resources (us-east-1, account 697345203222)

| | ID |
|---|---|
| VPC `bootcamp-vpc` (10.0.0.0/16) | `vpc-0917ed6d87b005f58` |
| Internet Gateway | `igw-0b05f13160e05bfc8` |
| NAT Gateway (EIP 3.219.62.36) | `nat-0a456faf68c5e5724` |
| App instances | `i-006dcbf0b26c73872`, `i-0375a3d0aebc05159`, `i-098084ed2ca7bb99f` |
| Data instance | `i-02bb4326af4a8a7b2` |
| ALB / Target group | `ce-app-alb` / `ce-app-tg` |

## Highlights
- **Multi-AZ HA** — subnets, app instances, and ALB all span two AZs; failover tested (see below).
- **Defense in depth** — SG-to-SG least-privilege chain **plus** routing isolation **plus** no public IPs on private tiers.
- **Isolated data tier** — no internet route at all, not just a firewall rule.
- **Keyless administration** — SSM Session Manager; no SSH, no bastion, no open port 22.
- **Stateless app** — any instance serves any request, enabling trivial scaling and failover.

## Reliability & security add-ons (should-haves, implemented)
- **Auto Scaling Group** — app tier runs behind `ce-app-asg` (min 2 / desired 3 / max 4) with a **CPU target-tracking** policy; a failed instance is now *replaced automatically*, not just restarted.
- **HTTPS** — ALB has an `:443` listener with an ACM certificate (self-signed for this demo) alongside `:80`.
- **Monitoring** — **VPC Flow Logs** to CloudWatch + **CloudWatch alarms** (unhealthy hosts, target 5XX).
- **Cost control** — [`app/manage.sh`](app/manage.sh) `stop`/`start`/`status` pauses compute (ASG → 0, data instance stopped) without tearing anything down.

## Testing results

| Test | Result |
|---|---|
| Target health | ✅ 3/3 healthy |
| Load distribution (18 reqs) | ✅ 6 / 6 / 6 across instances & AZs |
| App → Data connectivity | ✅ `"db":"up"` on all instances |
| Network isolation | ✅ private tiers have no public IP; only ALB reachable |
| Failover (stop 1 instance) | ✅ stayed up on survivors, auto-recovered in ~30s |

Details: **[tests/test-plan.md](tests/test-plan.md)** · **[tests/test-results.md](tests/test-results.md)** · **[tests/failover-test.md](tests/failover-test.md)**

## How to replicate

Prereqs: AWS CLI configured for `us-east-1`; a VPC with public + private (app) + isolated (data) subnets across 2 AZs, an IGW, a NAT Gateway, and the three tier security groups (see `config/`).

**One-shot:** run [`app/deploy.sh`](app/deploy.sh) (or `npm --prefix app run deploy`). It launches the data tier, injects the DB IP, launches the 3 app instances, and creates the ALB + target group + listener, then prints the ALB DNS. Resource IDs are pre-filled at the top of the script and can be overridden via environment variables.

Manual equivalent:
1. **Data tier** — launch an EC2 in an isolated data subnet with `data-tier-sg` running the simulated-DB listener on :3306. Note its private IP.
2. **App tier** — launch 3 EC2 instances across the two private app subnets with `app-tier-sg` (2 in AZ-a, 1 in AZ-b), user-data embeds [`app/app.py`](app/app.py) with `DB_HOST` set to the data IP.
3. **Load balancer** — create target group `ce-app-tg` (HTTP :80, health check `/health`), register the 3 instances, create an internet-facing ALB in the public subnets with `alb-sg`, and add an HTTP :80 listener forwarding to the target group.
4. **Verify** — `curl http://<ALB-DNS>/health` repeatedly; you should see all three instance IDs and `"db":"up"`.

> **Windows/Git Bash note:** prefix CLI calls that contain paths like `/health` with `MSYS_NO_PATHCONV=1` to stop Git Bash rewriting them into Windows paths.

## Cost
~**$101/month** if run 24/7 (NAT Gateway + ALB are ~57% of that). The single biggest saving is **tearing down the NAT Gateway and stopping instances when idle**. Full breakdown: **[COSTS.md](COSTS.md)**.

## Repository layout

```
├── README.md              ← you are here
├── ARCHITECTURE.md        ← detailed design, CIDR plan, HA
├── SECURITY.md            ← SG chain, isolation, IAM, gaps
├── COSTS.md               ← itemized cost + optimization
├── IMPROVEMENTS.md        ← roadmap, prod checklist, DR
├── architecture/          ← interactive HTML diagram
├── config/                ← live VPC / SG / ALB / instance config
├── app/                   ← application source + deploy scripts
├── tests/                 ← test plan, results, failover test
├── presentation/          ← slides, demo script, screenshots
└── docs/PROJECT-BRIEF.md  ← original assignment brief
```

## Documentation index
- **[ARCHITECTURE.md](ARCHITECTURE.md)** — components, network design, traffic flow, HA
- **[SECURITY.md](SECURITY.md)** — security groups, isolation, IAM, known gaps
- **[COSTS.md](COSTS.md)** — monthly breakdown, optimization, scaling projections
- **[IMPROVEMENTS.md](IMPROVEMENTS.md)** — short/long-term roadmap, DR plan
- **[docs/PROJECT-BRIEF.md](docs/PROJECT-BRIEF.md)** — the assignment requirements
