# Failover / High-Availability Test

**Date:** 2026-07-23 · **Region:** us-east-1 · **Method:** stop one application instance while continuously requesting the ALB.

## Objective
Prove the architecture survives the loss of a single EC2 instance with no manual intervention: the ALB detects the failure, removes the instance from rotation, keeps serving from the survivors, and automatically re-adds the instance when it recovers.

## Setup
- 3 application instances registered to target group `ce-app-tg` (health check `GET /health`, 10s interval, threshold 2).
- Victim: `i-098084ed2ca7bb99f` (`app-web-1b`, us-east-1b).
- Load generator: `curl http://<ALB-DNS>/health` every 2s for ~90s.

## Timeline & Results

| Phase | Observation |
|---|---|
| Baseline | 3/3 targets `healthy`, traffic balanced across all 3 |
| Stop victim | `ec2 stop-instances i-098084ed2ca7bb99f` |
| Detection window (~20s) | 3 requests failed (2× connection error, 1× HTTP 502) while the ALB completed 2 failed health checks |
| Victim removed | ALB target state → `unused` (`Target.InvalidState`); requests now served **only** by the 2 survivors |
| Steady state (degraded) | 42/45 requests HTTP 200; last 10 samples all 200 from `i-006dcbf0…` and `i-0375a3d0…` |
| Restart victim | `ec2 start-instances`; app auto-started via `systemd` (enabled unit) |
| Recovery | Victim `healthy` again within ~30s → back to 3/3 |
| Post-recovery | 12 requests balanced 4 / 5 / 3 across all three instances |

## Request outcome during the 90s window
```
 42  HTTP 200   (served successfully)
  1  HTTP 502   (in-flight to instance at moment of stop)
  2  connection error (before ALB marked target unhealthy)
```

## Conclusion — PASS
- **Single-instance failure is non-fatal.** ~93% of requests succeeded during the transition and 100% once the ALB removed the failed target (~20s).
- **Self-healing.** No manual step was needed to restore capacity — the `systemd` unit restarts the app on boot and the ALB re-registers the target automatically.
- **Multi-AZ matters.** Losing the only instance in us-east-1b left healthy capacity in us-east-1a, so the service stayed up.

## How to reduce the ~20s degraded window (future work)
- Lower health-check interval / unhealthy threshold (faster detection, more probes).
- Run an **Auto Scaling Group** so a replacement launches automatically instead of relying on the same instance restarting.
- Keep ≥2 instances per AZ so an AZ retains capacity even mid-failure.
