# Improvements & Next Steps

What I'd change to take this from a working bootcamp deployment to a production-ready system, organized by horizon.

## ✅ Already implemented (should-have bonus)
- **Auto Scaling Group** `ce-app-asg` (min 3 / desired 3 / max 4) with **CPU target-tracking** scaling.
- **HTTPS listener + ACM certificate** on the ALB (`:443`; self-signed for the demo).
- **VPC Flow Logs** → CloudWatch (`/vpc/ce-project-1/flowlogs`).
- **CloudWatch alarms** — unhealthy hosts, target 5XX.

## Short-term (0–3 months)

| Improvement | Why | Effort |
|---|---|---|
| **ACM public cert + custom domain** | Replace the self-signed cert; redirect 80→443 | Low |
| **Per-AZ NAT Gateway** | Remove the single-NAT SPOF for private egress | Low (cost trade-off) |
| **CloudWatch dashboard + SNS actions** | Visualize health; page on alarm | Medium |
| **S3 + SSM VPC endpoints** | Cut NAT data charges and reduce internet dependency | Low |
| **Secrets Manager for DB credentials** | Stop passing connection details in plain config | Low |

## Long-term (3–12 months)

| Improvement | Why |
|---|---|
| **RDS Multi-AZ (or Aurora)** replacing the simulated DB | Managed backups, automatic failover, patching, encryption at rest |
| **Infrastructure as Code (Terraform/CloudFormation)** | Reproducible, reviewable, version-controlled infra — no more click-ops |
| **CI/CD pipeline (GitHub Actions + CodeDeploy)** | Automated, tested deployments |
| **AWS WAF on the ALB** | Managed protection against L7 attacks and bots |
| **ElastiCache for shared session/state** | Enables fully stateless scaling and caching |
| **Blue-green / canary deployments** | Zero-downtime releases with fast rollback |
| **Multi-region (design)** | DR and latency; Route 53 failover routing |

## Production-readiness checklist

- [x] TLS on the ALB (HTTPS :443 listener) — *self-signed for demo; use ACM public cert + redirect 80→443 for prod*
- [x] App tier behind an Auto Scaling Group with min/max/desired (+ CPU target-tracking)
- [ ] Managed database (RDS/Aurora) Multi-AZ, encrypted, automated backups
- [ ] Per-AZ NAT Gateways (no single-AZ egress SPOF)
- [ ] Secrets in Secrets Manager / SSM Parameter Store (never in code)
- [ ] Least-privilege IAM everywhere; **root not used** for day-to-day (MFA on root)
- [x] Observability: CloudWatch alarms + VPC Flow Logs (dashboards/SNS actions still to add)
- [ ] WAF + Shield on public endpoints
- [ ] Infrastructure as Code; peer-reviewed changes
- [ ] Automated CI/CD with rollback
- [ ] Cost guardrails: budgets, alerts, Savings Plans for steady state
- [ ] Tagging standard for cost allocation and ownership

## Disaster recovery planning

- **Backups:** automated RDS snapshots (point-in-time recovery); AMI/EBS snapshots for app images.
- **RPO/RTO targets:** define acceptable data-loss and recovery windows; test them.
- **Multi-AZ (have) → multi-region (design):** replicate DB snapshots cross-region; Route 53 health-check failover to a warm/pilot-light standby.
- **Runbooks:** documented, rehearsed procedures for AZ loss, region loss, and data corruption.
- **Game days:** periodic failure injection (the failover test in `tests/failover-test.md` is a first step) to validate assumptions.

## What I'd do differently, in hindsight
- **Start with Infrastructure as Code.** The console/CLI click-ops here is fine for learning but doesn't reproduce cleanly; a Terraform module would make the whole stack one `apply`.
- **Use an ASG from day one** instead of fixed instances — same effort, real self-healing.
- **Provision an interface VPC endpoint for SSM** so management never depends on the NAT/internet path.
