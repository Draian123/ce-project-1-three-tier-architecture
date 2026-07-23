#!/usr/bin/env bash
#
# manage.sh - pause / resume the running stack to save cost WITHOUT tearing it down.
#
#   stop    scale the app Auto Scaling Group to 0 and stop the data instances.
#           NAT Gateway + ALB stay up (they can't be "stopped", only deleted),
#           so a small baseline (~$1.6/day) remains — nothing is destroyed.
#   start   bring the data instances back and scale the ASG to 3, then wait for
#           the ALB targets to go healthy and print the URLs.
#   status  show ASG, data instances, target health, and the endpoints.
#
# Usage:  bash manage.sh {stop|start|status}
#
set -euo pipefail
REGION="us-east-1"
ASG="ce-app-asg"
# Multi-AZ data tier: primary in AZ-a, standby in AZ-b
DATA_INSTANCES="i-02bb4326af4a8a7b2 i-0ac9214e7c05c0335"
TG_ARN="arn:aws:elasticloadbalancing:us-east-1:697345203222:targetgroup/ce-app-tg/3f16f11f811aa77e"
ALB_DNS="ce-app-alb-1960431634.us-east-1.elb.amazonaws.com"
aws() { command aws --region "$REGION" "$@"; }

case "${1:-}" in
  stop)
    echo ">> Scaling app ASG to 0 and stopping the data instances (NAT + ALB stay up)..."
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$ASG" --min-size 0 --desired-capacity 0
    aws ec2 stop-instances --instance-ids $DATA_INSTANCES --query 'StoppingInstances[].CurrentState.State' --output text
    echo ">> Paused. Compute is off; a small NAT+ALB baseline remains. Nothing was deleted."
    ;;
  start)
    echo ">> Starting data instances and scaling app ASG back to 3..."
    aws ec2 start-instances --instance-ids $DATA_INSTANCES --query 'StartingInstances[].CurrentState.State' --output text
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$ASG" --min-size 3 --desired-capacity 3
    aws ec2 wait instance-running --instance-ids $DATA_INSTANCES
    echo ">> Waiting for ALB targets to become healthy (~2-3 min while instances boot + run user-data)..."
    for i in $(seq 1 30); do
      H=$(aws elbv2 describe-target-health --target-group-arn "$TG_ARN" \
        --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`]|length(@)' --output text)
      echo "   healthy targets: ${H}/3"
      [ "$H" -ge 3 ] && break
      sleep 12
    done
    echo ">> Ready:"
    echo "     http://$ALB_DNS/"
    echo "     https://$ALB_DNS/   (self-signed cert -> browser warning is expected)"
    ;;
  status)
    echo "== Auto Scaling Group =="
    aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" \
      --query 'AutoScalingGroups[0].{Min:MinSize,Desired:DesiredCapacity,Max:MaxSize,Instances:Instances[].[InstanceId,AvailabilityZone,LifecycleState,HealthStatus]}' --output json
    echo "== Data instances (primary + standby) =="
    aws ec2 describe-instances --instance-ids $DATA_INSTANCES \
      --query 'Reservations[].Instances[].{Id:InstanceId,AZ:Placement.AvailabilityZone,State:State.Name,PrivateIp:PrivateIpAddress}' --output json
    echo "== Target health =="
    aws elbv2 describe-target-health --target-group-arn "$TG_ARN" \
      --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State]' --output text
    echo "== Endpoints =="
    echo "   http://$ALB_DNS/   |   https://$ALB_DNS/"
    ;;
  *)
    echo "Usage: bash manage.sh {stop|start|status}"; exit 1;;
esac
