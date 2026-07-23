# Demo Script — 3-Tier Cloud Architecture

**Total time:** 20 min presentation + 5 min Q&A. Live demo is ~5 min of that.
**Live endpoint:** http://ce-app-alb-1960431634.us-east-1.elb.amazonaws.com
**Golden rule:** have the backup screenshots (`screenshots/`) open in a tab in case the live demo fails.

---

## Before you start (setup checklist)
- [ ] Confirm the stack is running: `curl http://<ALB-DNS>/health` returns `"db":"up"`.
- [ ] Confirm 3/3 targets healthy in the EC2 → Target Groups console.
- [ ] Open tabs: (1) the app URL, (2) EC2 Instances, (3) VPC → Subnets/Route tables, (4) EC2 → Security Groups, (5) Target Group health, (6) `screenshots/` folder as backup.
- [ ] Have a terminal ready with the AWS CLI (`MSYS_NO_PATHCONV=1` already exported on Windows).

---

## 1. Architecture overview (5 min) — slides
Walk the diagram (`architecture/architecture-diagram.html`). Say:
- "One VPC, `10.0.0.0/16`, across **two Availability Zones** for high availability."
- "**Three tiers**: presentation (the ALB, in public subnets), application (3 EC2 in private subnets), data (isolated subnet, no internet route)."
- "Traffic flows top-down: internet → IGW → ALB → app instances → data. Each hop is gated by a security group that only trusts the tier in front of it."
- Key decision to highlight: "the data tier has its **own route table with no `0.0.0.0/0` route** — it's isolated by routing *and* by security group. Defense in depth."

## 2. Live demo (5 min)

### 2a. The app is load balanced
1. Open the ALB URL in the browser → the status page shows **Instance ID**, **AZ**, and a green **Data tier: Connected** pill.
2. **Refresh 4–5 times** → point out the **Instance ID changes** and the **AZ flips between us-east-1a and 1b**. "Same URL, different backend each time — that's the ALB distributing load across all three instances in both AZs."
3. Switch to the terminal:
   ```bash
   for i in $(seq 1 12); do curl -s http://<ALB-DNS>/health; echo; done \
     | grep -o '"instance": "[^"]*"' | sort | uniq -c
   ```
   → shows an even spread across all three instance IDs.

### 2b. The health endpoint
```bash
curl -s http://<ALB-DNS>/health
```
"This JSON is exactly what the ALB polls every 10 seconds. `db:up` means this instance can reach the data tier — the app is verifying the full path on every check."

### 2c. Security isolation (the "try to break in" moment)
- In the EC2 console, show the app instances have **no public IPv4** — "there is no address to attack from the internet; the only way in is the ALB."
- Show the three security groups: ALB SG (80/443 from `0.0.0.0/0`) → App SG (80 from **ALB SG only**) → Data SG (3306/5432 from **App SG only**). "Least privilege, expressed as security-group references, not IP ranges."
- Optional: show the data subnet's route table has **only the local route** — no path to the internet.

### 2d. Failover (if time allows — otherwise use the recorded result)
- In the console, **stop one app instance**.
- Keep refreshing the app URL → it keeps serving from the other two; the stopped instance's ID disappears.
- Show the target group marking it unhealthy, then **start it again** and watch it rejoin.
- If you'd rather not risk it live: show `tests/failover-test.md` and the recorded GIF. "I tested this — 93% of requests succeeded even during the ~20-second detection window, and it self-healed with no manual step."

## 3. Challenges & solutions (3 min)
- **Blackholed NAT route.** The reused VPC pointed at a deleted NAT Gateway (route in `blackhole`). Fix: created a new NAT Gateway + Elastic IP and repaired the app route table.
- **Data-tier isolation.** Originally all private subnets shared one route table. Split the data tier onto its own route table with no internet route → true isolation.
- **Testing private instances with no SSH.** Used **SSM Session Manager / Run Command** instead of a bastion — no keys, no open port 22.
- **Tooling gotcha.** Git Bash rewrote `/health` into a Windows path in the CLI call; fixed with `MSYS_NO_PATHCONV=1`.

## 4. Cost analysis (3 min)
- "~**$101/month** at 24/7. The **NAT Gateway and ALB are ~57%** of that and run regardless of traffic."
- "Biggest lever isn't instance size — it's **not leaving it running when idle**. Tearing down NAT + stopping instances outside work hours saves ~50–70%."
- Other optimizations: S3/SSM VPC endpoints (cut NAT data charges), Graviton `t4g`, Savings Plans for steady-state prod. (See `COSTS.md`.)

## 5. Improvements & next steps (2 min)
- Short term: **HTTPS listener + ACM**, **Auto Scaling Group** (real self-healing), per-AZ NAT, CloudWatch alarms.
- Long term: **RDS Multi-AZ** for the data tier, **Infrastructure as Code (Terraform)**, CI/CD, WAF.
- "If I did it again I'd start with IaC and an ASG from day one." (See `IMPROVEMENTS.md`.)

## 6. Q&A (5 min)
Likely questions + crisp answers:
- **"Why one NAT, not per-AZ?"** Cost vs. HA trade-off; documented. Per-AZ NAT is the first production upgrade.
- **"How is the DB protected?"** Two independent controls: SG allows only the app SG, and the subnet has no internet route at all.
- **"How do you patch private instances?"** Outbound via NAT; management via SSM. No inbound access needed.
- **"Is the app stateless?"** Yes — any instance serves any request, which is what makes balancing and failover trivial.
- **"What breaks if an AZ goes down?"** The other AZ keeps serving; the single NAT (in AZ-a) is the current gap for private egress — the per-AZ NAT fix addresses it.

---

### If the live demo fails
Don't troubleshoot on stage. Say: "Let me show the captured results," switch to `screenshots/` and the recorded GIF, and narrate what they'd have seen. You lose nothing on the rubric — the backup plan *is* part of the grade.
