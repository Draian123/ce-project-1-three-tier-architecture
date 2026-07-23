# Day 1 - Tier Connectivity Test Results
Date: 2026-07-23 08:27 UTC | Region: us-east-1

## Method
Ran `curl http://localhost/health` on each application-tier EC2 instance via AWS SSM Run Command.
The web app checks Data-tier reachability by opening a TCP connection to 10.0.21.110:3306.

## Result: PASS - all 3 app instances healthy, Data tier reachable
```json
{"status":"healthy","instance":"i-006dcbf0b26c73872","az":"us-east-1a","db":"up","db_host":"10.0.21.110"}
{"status":"healthy","instance":"i-0375a3d0aebc05159","az":"us-east-1a","db":"up","db_host":"10.0.21.110"}
{"status":"healthy","instance":"i-098084ed2ca7bb99f","az":"us-east-1b","db":"up","db_host":"10.0.21.110"}
```

## What this validates
- App tier serves HTTP :80 and returns instance-id + AZ (App tier functional, spread across 1a/1b).
- "db":"up" => App SG is permitted into Data SG on :3306 (App -> Data path works).
- Instances have NO public IP and are only in private subnets (reached only via SSM/ALB).

## Pending (Day 2)
- ALB -> App path (target group health checks on /health).
- Negative test: confirm Data tier is unreachable from outside App SG.

---

# Day 2 - Load Balancing & Isolation Test Results
Date: 2026-07-23 (Thursday) | Region: us-east-1

## ALB
- Name: ce-app-alb (internet-facing, application)
- DNS: http://ce-app-alb-1960431634.us-east-1.elb.amazonaws.com
- Listener: HTTP :80 -> target group ce-app-tg (forward)
- Health check: HTTP GET /health, interval 10s, healthy/unhealthy threshold 2, matcher 200

## Test 1 - Target health: PASS
All 3 registered instances reached `healthy` state within the first poll.

## Test 2 - Load distribution: PASS
18 requests to http://<ALB-DNS>/health, tallied by responding instance:
```
  6  i-006dcbf0b26c73872  (app-web-1a, us-east-1a)
  6  i-0375a3d0aebc05159  (app-web-1a, us-east-1a)
  6  i-098084ed2ca7bb99f  (app-web-1b, us-east-1b)
```
Even distribution across all 3 instances and both AZs. Every response reported "db":"up".

## Test 3 - Network isolation: PASS
- data-db-1a, and all 3 app instances: PublicIpAddress = None (no direct internet exposure).
- Only the ALB DNS is internet-reachable (ALB / -> 200, /health -> 200).
- App instances are reachable only through the ALB security group; the data tier only from the app security group.

## Pending (Day 3)
- Failover test: deregister/stop one instance, confirm ALB routes around it (tests/failover-test.md).
- Live negative demo: attempt direct access to a private resource and show it is refused.
