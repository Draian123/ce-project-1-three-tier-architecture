# Test Plan

Testing methodology for the 3-tier architecture. Each test maps to a project requirement and has a clear pass/fail criterion.

| # | Test | Method | Pass criterion | Result |
|---|---|---|---|---|
| 1 | App tier serves content | `curl localhost/health` on each instance via SSM | HTTP 200 + correct instance-id/AZ | ✅ PASS |
| 2 | App → Data connectivity | App health check opens TCP to `10.0.21.110:3306` | `"db":"up"` on all instances | ✅ PASS |
| 3 | Target registration & health | `elbv2 describe-target-health` | 3/3 `healthy` | ✅ PASS |
| 4 | Load distribution | 18 requests to ALB DNS, tally by instance | Traffic spread across all 3 / both AZs | ✅ PASS (6/6/6) |
| 5 | Network isolation | `describe-instances` public IPs; direct-access attempt | Private tiers have no public IP; only ALB reachable | ✅ PASS |
| 6 | Failover / HA | Stop 1 instance, sample ALB, restart | Service stays up on survivors; auto-recovers | ✅ PASS |

## Tools
- **AWS CLI** — resource creation, inspection, health queries.
- **AWS SSM Run Command / Session Manager** — command execution on private instances (no bastion, no SSH keys, no inbound ports).
- **curl** — external validation via the ALB's public DNS.

## Environment
- Region: `us-east-1`, VPC `vpc-0917ed6d87b005f58` (10.0.0.0/16).
- ALB DNS: `http://ce-app-alb-1960431634.us-east-1.elb.amazonaws.com`

## Negative tests (for the live demo)
- Attempt to reach an app instance's private IP directly from the internet → no route (instances have no public IP).
- Attempt a DB connection from a host **not** in `app-tier-sg-3tier` → refused by `data-tier-sg-3tier` (least-privilege SG).

See `test-results.md` and `failover-test.md` for full output.
