# Security

Security strategy for the 3-tier architecture, built on **defense in depth** and **least privilege**. Each layer restricts what the layer in front of it can reach, so a compromise at one tier does not grant access to the next.

## Security-group chain (the core control)

Traffic is allowed **tier-to-tier only**, using security-group references (not CIDR ranges) so rules stay correct even as instance IPs change.

| Security group | ID | Inbound rule | Source |
|---|---|---|---|
| `alb-sg-3tier` | `sg-0afa31c9844b6cea0` | TCP 80, 443 | `0.0.0.0/0` (public) |
| `app-tier-sg-3tier` | `sg-0b8d55053c76f6e66` | TCP 80 | **`alb-sg-3tier` only** |
| `data-tier-sg-3tier` | `sg-01c6914f0ca937cb1` | TCP 3306, 5432 | **`app-tier-sg-3tier` only** |

**Least privilege in practice:**
- The internet can reach **only** the ALB — never an application or database instance.
- Application instances accept traffic **only** from the ALB's security group — direct hits to their IPs are dropped.
- The database accepts traffic **only** from the application security group — nothing else in the VPC (or internet) can open a DB connection.

## Network isolation (independent of security groups)

Security groups are one layer; routing is a second, independent one.

- **No public IPs on private tiers.** All 3 app instances and the data instance have `PublicIpAddress = None`. There is no address to attack from the internet.
- **Data tier has no internet route.** `data-rt` contains only the `local` route — the data subnets cannot reach, and cannot be reached from, the internet even if a security group were misconfigured.
- **Outbound-only for the app tier.** App instances reach the internet through the NAT Gateway for patching, but the internet cannot initiate connections back.

This means the data tier is protected by **two** controls at once: a restrictive security group *and* the absence of any internet route.

## Identity & access (IAM)

- Instances use the **`ec2-s3-cloudwatch-role`** instance profile:
  - `AmazonSSMManagedInstanceCore` — administration via SSM Session Manager.
  - `CloudWatchAgentServerPolicy` — metrics/logs publishing.
- **No long-lived credentials on instances.** No access keys are baked into user-data or config; the app uses only the instance role.
- **No SSH.** Administration is via SSM, so there are **no key pairs to manage, no port 22 open, and no bastion host** to secure.

## Security best practices applied

- ✅ **Least privilege** security groups, expressed as SG-to-SG references.
- ✅ **Defense in depth** — SG rules + routing isolation + no public IPs are three overlapping controls.
- ✅ **No inbound SSH / no bastion** — SSM-only management.
- ✅ **IMDSv2** used by the app for metadata (token-based, mitigates SSRF-based credential theft).
- ✅ **Private-subnet workloads** — only the load balancer is internet-facing.
- ✅ **Isolated data tier** with no route to the internet.

## Known gaps & mitigations (roadmap)

| Gap | Risk | Mitigation (see `IMPROVEMENTS.md`) |
|---|---|---|
| Listener is HTTP :80 (no TLS) | Traffic in cleartext | Add HTTPS listener + ACM certificate; redirect 80→443 |
| Simulated DB, no auth/encryption | Not production-grade | Move to RDS with IAM/secret auth + encryption at rest (KMS) |
| No VPC Flow Logs | Limited network forensics | Enable Flow Logs to CloudWatch/S3 |
| No WAF on the ALB | L7 attacks (injection, bots) | Attach AWS WAF managed rule sets |
| Root account in use for CLI | Broad blast radius | Use an IAM admin/role with MFA; reserve root for break-glass |
| Single NAT / no secrets manager | Availability + secret handling | Per-AZ NAT; AWS Secrets Manager for DB credentials |

## Verification
Isolation and least-privilege were tested — see `tests/test-results.md` (Test 5: no public IPs; only ALB reachable) and `tests/test-plan.md` (negative tests for the live demo).
