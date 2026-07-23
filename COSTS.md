# Cost Analysis

Estimated **on-demand** cost in `us-east-1`, assuming 24/7 operation (~730 hours/month). Figures are list price at time of writing; actual bills vary with data transfer and LCU usage.

## Monthly cost breakdown

| Component | Qty | Unit rate | Monthly | Notes |
|---|---|---:|---:|---|
| **NAT Gateway** | 1 | $0.045/hr + $0.045/GB | **~$35** | ~$32.85 hourly + data processing. **Largest single line item.** |
| **Application Load Balancer** | 1 | $0.0225/hr + LCU | **~$22** | ~$16.43 hourly + ~$6 LCU at low traffic |
| **EC2 t3.micro** | 4 | $0.0104/hr | **~$30** | 3 app + 1 data; $7.59 each |
| **EBS gp3 storage** | 32 GB | $0.08/GB-mo | **~$2.56** | 4 × 8 GB root volumes |
| **Public IPv4 addresses** | 3 | $0.005/hr | **~$11** | 1 NAT EIP + 2 ALB node IPs (charged since Feb 2024) |
| | | | **≈ $101 / month** | if left running continuously |

> The private tier instances have **no public IPv4**, which avoids extra IPv4 charges — a small but real saving that also improves security.

## Where the money goes
The **NAT Gateway + ALB together are ~57%** of the bill and run whether or not anyone is using the app. Compute (EC2) is only ~30% and scales with actual need. For a bootcamp/dev project, *idle time is the enemy*, not instance size.

## Cost optimization strategies

### Implemented
- **Single NAT Gateway** (not one per AZ) — halves NAT hourly cost vs. the multi-AZ pattern. Trade-off documented in `ARCHITECTURE.md` (AZ-a NAT is a SPOF for private egress).
- **t3.micro right-sizing** — smallest burstable type adequate for a stateless demo app.
- **No public IPs on private tiers** — avoids ~$0.005/hr per unused address.
- **SSM instead of a bastion** — no extra always-on bastion instance to pay for.

### Recommended (biggest levers first)
1. **Stop resources when idle.** Deleting the NAT Gateway + stopping the 4 instances overnight/weekends can cut the bill by **50–70%**. NAT is the highest-value thing to tear down between work sessions.
2. **VPC endpoints for SSM & S3** (Gateway endpoint for S3 is free; interface endpoints for SSM are cheap) — removes NAT **data-processing** charges for that traffic.
3. **Graviton (t4g.micro)** — ~20% cheaper than t3.micro for the same workload.
4. **Savings Plans / Reserved Instances** — for a steady-state production fleet, a 1-year Compute Savings Plan saves ~30–40% on EC2.
5. **NAT instance instead of NAT Gateway** for very-low-traffic dev — a `t4g.nano` NAT instance is ~$3–4/mo vs. ~$35, trading managed HA for cost (dev only).

## ROI examples

| Action | Effort | Monthly saving |
|---|---|---|
| Tear down NAT + stop instances outside working hours (~12h/day) | Low (one script) | **~$45–55** |
| Add S3 + SSM VPC endpoints | Low | NAT data charges → ~$0 for that traffic |
| Move EC2 to t4g.micro | Low | **~$6** |
| 1-yr Compute Savings Plan (prod) | Medium | **~$10–12** on compute |

## Scaling cost projections

| Scenario | Added monthly cost |
|---|---|
| Scale app tier 3 → 6 instances | +~$23 (EC2) + modest LCU growth |
| Add per-AZ NAT (2nd NAT for HA) | +~$35 |
| Add RDS `db.t3.micro` Multi-AZ | +~$25–30 (2× instance + storage) |
| Add HTTPS (ACM cert) | $0 — ACM public certs are free |

**Takeaway:** the architecture is cheap to run *per request* because compute scales horizontally, but the fixed NAT + ALB baseline dominates at low usage. The single most effective cost control for this project is **not leaving it running when idle.**
