#!/usr/bin/env bash
#
# deploy.sh - Deploy the application + data tiers and the load balancer for
#             the 3-tier architecture. Assumes the network layer (VPC, subnets,
#             IGW, NAT, route tables) and the three tier security groups already
#             exist. app.py (in this folder) is the single source of truth for
#             the web application.
#
# Usage:  bash deploy.sh
# Prereqs: AWS CLI configured for the target account/region.
#
set -euo pipefail

# Windows/Git Bash: stop MSYS rewriting "/health" etc. into a Windows path.
export MSYS_NO_PATHCONV=1

# ------------------------------------------------------------------ config ----
# Pre-filled with this project's real IDs; override via environment if reusing.
REGION="${REGION:-us-east-1}"
VPC_ID="${VPC_ID:-vpc-0917ed6d87b005f58}"
APP_SUBNET_A="${APP_SUBNET_A:-subnet-0a9bef3ba8fa34d1e}"   # private-subnet-1a
APP_SUBNET_B="${APP_SUBNET_B:-subnet-049f32c8e8e534e85}"   # private-subnet-1b
DATA_SUBNET="${DATA_SUBNET:-subnet-02b652b1affd7912a}"     # data-subnet-1a
PUB_SUBNET_A="${PUB_SUBNET_A:-subnet-0a8a1e9afe3d8117b}"   # public-subnet-1a
PUB_SUBNET_B="${PUB_SUBNET_B:-subnet-0c28b42a4bdc84fda}"   # public-subnet-1b
ALB_SG="${ALB_SG:-sg-0afa31c9844b6cea0}"
APP_SG="${APP_SG:-sg-0b8d55053c76f6e66}"
DATA_SG="${DATA_SG:-sg-01c6914f0ca937cb1}"
INSTANCE_PROFILE="${INSTANCE_PROFILE:-ec2-s3-cloudwatch-role}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.micro}"
DB_PORT="${DB_PORT:-3306}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

aws() { command aws --region "$REGION" "$@"; }

echo ">> Resolving latest Amazon Linux 2023 AMI..."
AMI="${AMI:-$(aws ec2 describe-images --owners amazon \
  --filters 'Name=name,Values=al2023-ami-2023.*-x86_64' 'Name=state,Values=available' \
  --query 'reverse(sort_by(Images,&CreationDate))[0].ImageId' --output text)}"
echo "   AMI = $AMI"

# ----------------------------------------------------------- data tier --------
DATA_USERDATA=$(cat <<'EOF'
#!/bin/bash
# Tier 3 - simulated database: TCP listener on :3306 (isolated subnet, no internet)
cat >/opt/fakedb.py <<'PY'
import socket
s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
s.bind(('0.0.0.0',3306)); s.listen(64)
while True:
    try:
        c,_=s.accept(); c.sendall(b'OK simulated-db\n'); c.close()
    except Exception:
        pass
PY
cat >/etc/systemd/system/fakedb.service <<'UNIT'
[Unit]
Description=Simulated DB listener (:3306)
After=network.target
[Service]
ExecStart=/usr/bin/python3 /opt/fakedb.py
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now fakedb.service
EOF
)

echo ">> Launching data-tier instance..."
DATA_ID=$(aws ec2 run-instances \
  --image-id "$AMI" --instance-type "$INSTANCE_TYPE" \
  --subnet-id "$DATA_SUBNET" --security-group-ids "$DATA_SG" \
  --iam-instance-profile "Name=$INSTANCE_PROFILE" \
  --user-data "$DATA_USERDATA" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=data-db-1a},{Key=Tier,Value=data},{Key=Project,Value=ce-project-1}]' \
  --query 'Instances[0].InstanceId' --output text)
DATA_IP=$(aws ec2 describe-instances --instance-ids "$DATA_ID" \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
echo "   data instance $DATA_ID @ $DATA_IP"

# ----------------------------------------------------------- app tier ---------
# Build app user-data by embedding app.py (single source of truth) + a systemd
# unit that injects DB_HOST/DB_PORT as environment variables.
APP_PY="$(cat "$SCRIPT_DIR/app.py")"
APP_USERDATA="#!/bin/bash
cat >/opt/app.py <<'PYEOF'
${APP_PY}
PYEOF
cat >/etc/systemd/system/webapp.service <<UNIT
[Unit]
Description=3-tier web app (:80)
After=network.target
[Service]
Environment=DB_HOST=${DATA_IP}
Environment=DB_PORT=${DB_PORT}
ExecStart=/usr/bin/python3 /opt/app.py
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now webapp.service
"

echo ">> Launching 3 app-tier instances (2 in AZ-a, 1 in AZ-b)..."
APP_IDS=$(aws ec2 run-instances \
  --image-id "$AMI" --instance-type "$INSTANCE_TYPE" --count 2 \
  --subnet-id "$APP_SUBNET_A" --security-group-ids "$APP_SG" \
  --iam-instance-profile "Name=$INSTANCE_PROFILE" \
  --user-data "$APP_USERDATA" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=app-web-1a},{Key=Tier,Value=app},{Key=Project,Value=ce-project-1}]' \
  --query 'Instances[].InstanceId' --output text)
APP_IDS="$APP_IDS $(aws ec2 run-instances \
  --image-id "$AMI" --instance-type "$INSTANCE_TYPE" --count 1 \
  --subnet-id "$APP_SUBNET_B" --security-group-ids "$APP_SG" \
  --iam-instance-profile "Name=$INSTANCE_PROFILE" \
  --user-data "$APP_USERDATA" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=app-web-1b},{Key=Tier,Value=app},{Key=Project,Value=ce-project-1}]' \
  --query 'Instances[].InstanceId' --output text)"
echo "   app instances: $APP_IDS"

# ------------------------------------------------------- load balancer --------
echo ">> Creating target group + ALB + listener..."
TG=$(aws elbv2 create-target-group --name ce-app-tg \
  --protocol HTTP --port 80 --vpc-id "$VPC_ID" --target-type instance \
  --health-check-protocol HTTP --health-check-path /health \
  --health-check-interval-seconds 10 --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 --unhealthy-threshold-count 2 --matcher HttpCode=200 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

TARGETS=""; for id in $APP_IDS; do TARGETS="$TARGETS Id=$id"; done
aws elbv2 register-targets --target-group-arn "$TG" --targets $TARGETS

ALB=$(aws elbv2 create-load-balancer --name ce-app-alb \
  --type application --scheme internet-facing --ip-address-type ipv4 \
  --subnets "$PUB_SUBNET_A" "$PUB_SUBNET_B" --security-groups "$ALB_SG" \
  --tags Key=Project,Value=ce-project-1 \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

aws elbv2 create-listener --load-balancer-arn "$ALB" \
  --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$TG" \
  --query 'Listeners[0].ListenerArn' --output text >/dev/null

echo ">> Waiting for ALB to become available..."
aws elbv2 wait load-balancer-available --load-balancer-arns "$ALB"
DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns "$ALB" \
  --query 'LoadBalancers[0].DNSName' --output text)

echo
echo "=========================================================="
echo " Deployment complete."
echo "   Data instance : $DATA_ID ($DATA_IP)"
echo "   App instances : $APP_IDS"
echo "   ALB DNS       : http://$DNS"
echo "   Test          : curl http://$DNS/health   (repeat to see load balancing)"
echo "=========================================================="
