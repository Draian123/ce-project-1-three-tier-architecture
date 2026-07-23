# Presentation Plan

**Format:** 20 min + 5 min Q&A · **Deck:** `three-tier-slides.pptx` (22 slides, screenshots embedded) · **No live demo** — presented entirely from the AWS-console screenshots.

## Flow at a glance
Cover → Architecture → **Network → Security → Compute/Load balancing → Auto Scaling → HTTPS/Monitoring → Multi-AZ data + app** → Results → Cost → Challenges → Improvements → Q&A.

Each console screenshot has talking points beside it on its slide — you narrate the picture, you don't read the slide.

## Slide-by-slide

| # | Slide | ~min | Say this |
|---|---|---|---|
| 1 | Cover | 0:30 | "A production-shaped 3-tier app on AWS. Since the infra is torn down to save cost, I'll walk it through the real console screenshots I captured." |
| 2 | Architecture diagram | 2:30 | Walk the tiers top→down. VPC /16, 2 AZs. Traffic: internet → IGW → ALB → app → data. Each hop gated by a security group. Call out the **isolated data tier**. |
| 3 | VPC & subnets `01` | 1:00 | 6 subnets, 2 AZs, tier-per-row. Octet scheme encodes tier + AZ. |
| 4 | Data-tier route table `02` | 1:00 | `data-rt` has **only the local route** — no `0.0.0.0/0`. Isolated by *routing*, not just a firewall. |
| 5 | Security groups `03` | 1:00 | Three SGs, one per tier — the ALB→App→Data chain. |
| 6 | App SG rules `04` | 1:00 | App accepts `:80` **from the ALB SG only** — least privilege via SG references. |
| 7 | Instances `05` | 0:50 | App + data instances across both AZs, **no public IP** on private tiers. |
| 8 | Load balancer `06` | 0:50 | Internet-facing ALB, listeners **:80 and :443**, both AZs. |
| 9 | Target group `07` | 0:50 | **3/3 healthy**, health check `/health`. Mention the load-balancing GIF (traffic hits different instances). |
| 10 | Auto Scaling Group `08` | 0:45 | min 3 / desired 3 / max 4 — a failed instance is **relaunched automatically**. |
| 11 | Scaling policy `09` | 0:45 | CPU target-tracking at 50%. *Story:* it scaled the idle tier down — I set the floor to 3 to keep the HA baseline. |
| 12 | HTTPS / ACM `10` | 0:40 | TLS on the ALB, ACM cert (self-signed for the demo). |
| 13 | CloudWatch alarms `11` | 0:40 | Alarms on unhealthy hosts + target 5XX. |
| 14 | VPC Flow Logs `12` | 0:40 | All VPC traffic → CloudWatch for forensics. |
| 15 | Multi-AZ data `15` | 0:50 | Primary in 1a, **standby in 1b** — the app fails DB connections over between them. |
| 16 | App over HTTP `12-app-http` | 0:50 | Instance-id, AZ, "Data tier: Connected (Multi-AZ)". Refresh = different instance. |
| 17 | App over HTTPS `14` | 0:30 | Same app over TLS. Cert warning is expected (self-signed). |
| 18 | Test results | 1:30 | 3/3 healthy · 6/6/6 load spread · ~30s app-tier recovery · **data-tier failover primary→standby**. |
| 19 | Cost | 1:30 | ~$101/mo running; NAT+ALB are ~57%. Biggest lever = don't run idle. **Torn down → $0** now. |
| 20 | Challenges & solutions | 1:00 | Blackholed NAT route; data isolation; idle scale-in fix; SSM instead of SSH. |
| 21 | Improvements | 1:00 | Done as bonus: ASG, HTTPS, monitoring, Multi-AZ data. Next: real RDS Multi-AZ, per-AZ NAT, IaC, CI/CD. |
| 22 | Thank you / Q&A | — | Repo link on screen. Take questions. |

**Running total ≈ 20 min.** Screenshot slides move fast (30–60s); spend your time on slides 2, 18, 19.

## Q&A prep (likely questions)
- **"Why one NAT?"** Cost vs HA trade-off; per-AZ NAT is the first prod upgrade.
- **"How is the DB protected?"** Two independent controls — restrictive SG *and* no internet route on the subnet.
- **"Is it really Multi-AZ?"** App tier (ASG) + ALB + data tier all span 2 AZs; I demoed data failover primary→standby.
- **"Real database?"** It's a simulated DB with app-level failover; **RDS Multi-AZ** is the managed production path (in IMPROVEMENTS.md).
- **"You tore it down — can you prove it ran?"** Yes: every screenshot is the live console, plus the load-balancing GIF and the test logs in `tests/`.

## If asked to show it live
The network foundation still exists (free). `bash app/deploy.sh` recreates the ALB + instances in a few minutes if you want a live URL — but the screenshots cover everything.
