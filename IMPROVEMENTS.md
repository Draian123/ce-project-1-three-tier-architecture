# Improvements & Next Steps

What I'd change to take this from a working bootcamp deployment to a production-ready system, organized by horizon.

## Short-term (0–3 months)

| Improvement | Why | Effort |
|---|---|---|
| **HTTPS listener + ACM certificate** | Encrypt traffic in transit; redirect 80→443 | Low (ACM certs are free) |
| **Auto Scaling Group for the app tier** | Replace the fixed 3 instances so failures self-heal and capacity follows demand | Medium |
| **Per-AZ NAT Gateway** | Remove the single-NAT SPOF for private egress | Low (cost trade-off) |
| **VPC Flow Logs** | Network forensics & troubleshooting | Low |
| **CloudWatch alarms + dashboard** | Alert on unhealthy hosts, 5xx, CPU; visualize health | Medium |
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

- [ ] TLS everywhere (HTTPS listener, redirect from 80)
- [ ] App tier behind an Auto Scaling Group with min/max/desired
- [ ] Managed database (RDS/Aurora) Multi-AZ, encrypted, automated backups
- [ ] Per-AZ NAT Gateways (no single-AZ egress SPOF)
- [ ] Secrets in Secrets Manager / SSM Parameter Store (never in code)
- [ ] Least-privilege IAM everywhere; **root not used** for day-to-day (MFA on root)
- [ ] Observability: CloudWatch alarms, dashboards, centralized logs, Flow Logs
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
