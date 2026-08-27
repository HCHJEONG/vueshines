#!/usr/bin/env bash
set -euo pipefail

: "${AWS_BASTION_HOST:=aws-bastion}"
: "${AWS_REGION:=ap-northeast-2}"
: "${ALB_NAME:=penvot-internet-facing-1}"
: "${HOST_NAME:=vueshines.penvot.com}"
: "${HOSTED_ZONE_NAME:=penvot.com.}"
: "${TARGET_GROUP_NAME:=vueshines-tg}"
: "${TARGET_PORT:=8180}"
: "${RULE_PRIORITY:=92}"
: "${TARGET_PRIVATE_IP:=172.31.76.194}"
: "${HEALTH_PATH:=/api/health}"

printf '[vueshines alb] host: %s\n' "$HOST_NAME"
printf '[vueshines alb] target: %s:%s%s\n' "$TARGET_PRIVATE_IP" "$TARGET_PORT" "$HEALTH_PATH"
read -r -p 'Create or update the AWS ALB, target group, security group rule, and DNS record? [y/N] ' answer
if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
  printf '[vueshines alb] cancelled\n'
  exit 1
fi

ssh "$AWS_BASTION_HOST" \
  AWS_REGION="$AWS_REGION" \
  ALB_NAME="$ALB_NAME" \
  HOST_NAME="$HOST_NAME" \
  HOSTED_ZONE_NAME="$HOSTED_ZONE_NAME" \
  TARGET_GROUP_NAME="$TARGET_GROUP_NAME" \
  TARGET_PORT="$TARGET_PORT" \
  RULE_PRIORITY="$RULE_PRIORITY" \
  TARGET_PRIVATE_IP="$TARGET_PRIVATE_IP" \
  HEALTH_PATH="$HEALTH_PATH" \
  bash -s <<'REMOTE_AWS'
set -euo pipefail
export AWS_DEFAULT_REGION="$AWS_REGION"

ALB_ARN="$(aws elbv2 describe-load-balancers --names "$ALB_NAME" --query 'LoadBalancers[0].LoadBalancerArn' --output text)"
ALB_DNS="$(aws elbv2 describe-load-balancers --names "$ALB_NAME" --query 'LoadBalancers[0].DNSName' --output text)"
ALB_ZONE_ID="$(aws elbv2 describe-load-balancers --names "$ALB_NAME" --query 'LoadBalancers[0].CanonicalHostedZoneId' --output text)"
VPC_ID="$(aws elbv2 describe-load-balancers --names "$ALB_NAME" --query 'LoadBalancers[0].VpcId' --output text)"
ALB_SG="$(aws elbv2 describe-load-balancers --names "$ALB_NAME" --query 'LoadBalancers[0].SecurityGroups[0]' --output text)"
LISTENER_ARN="$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" --query 'Listeners[?Port==`443`].ListenerArn | [0]' --output text)"
INSTANCE_ID="$(aws ec2 describe-instances --filters "Name=private-ip-address,Values=$TARGET_PRIVATE_IP" 'Name=instance-state-name,Values=running' --query 'Reservations[0].Instances[0].InstanceId' --output text)"
INSTANCE_SG="$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)"

TARGET_GROUP_ARN="$(aws elbv2 describe-target-groups --names "$TARGET_GROUP_NAME" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)"
if [ -z "$TARGET_GROUP_ARN" ] || [ "$TARGET_GROUP_ARN" = None ]; then
  TARGET_GROUP_ARN="$(aws elbv2 create-target-group \
    --name "$TARGET_GROUP_NAME" \
    --protocol HTTP \
    --port "$TARGET_PORT" \
    --target-type instance \
    --vpc-id "$VPC_ID" \
    --health-check-path "$HEALTH_PATH" \
    --matcher HttpCode=200 \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)"
fi

aws elbv2 register-targets --target-group-arn "$TARGET_GROUP_ARN" --targets "Id=$INSTANCE_ID,Port=$TARGET_PORT"

EXISTING_RULE="$(aws elbv2 describe-rules --listener-arn "$LISTENER_ARN" --query "Rules[?Conditions[?Field=='host-header' && contains(Values, '$HOST_NAME')]].RuleArn | [0]" --output text)"
if [ -z "$EXISTING_RULE" ] || [ "$EXISTING_RULE" = None ]; then
  USED_PRIORITY="$(aws elbv2 describe-rules --listener-arn "$LISTENER_ARN" --query "Rules[?Priority=='$RULE_PRIORITY'].RuleArn | [0]" --output text)"
  if [ -n "$USED_PRIORITY" ] && [ "$USED_PRIORITY" != None ]; then
    printf 'ALB rule priority %s is already in use\n' "$RULE_PRIORITY" >&2
    exit 1
  fi
  aws elbv2 create-rule \
    --listener-arn "$LISTENER_ARN" \
    --priority "$RULE_PRIORITY" \
    --conditions "Field=host-header,Values=$HOST_NAME" \
    --actions "Type=forward,TargetGroupArn=$TARGET_GROUP_ARN" >/dev/null
else
  aws elbv2 modify-rule \
    --rule-arn "$EXISTING_RULE" \
    --conditions "Field=host-header,Values=$HOST_NAME" \
    --actions "Type=forward,TargetGroupArn=$TARGET_GROUP_ARN" >/dev/null
fi

if ! aws ec2 authorize-security-group-ingress \
  --group-id "$INSTANCE_SG" \
  --ip-permissions "IpProtocol=tcp,FromPort=$TARGET_PORT,ToPort=$TARGET_PORT,UserIdGroupPairs=[{GroupId=$ALB_SG,Description=vueshines-alb}]" >/dev/null 2>&1; then
  printf 'security group ingress already exists or requires manual verification\n'
fi

HOSTED_ZONE_ID="$(aws route53 list-hosted-zones-by-name --dns-name "$HOSTED_ZONE_NAME" --query 'HostedZones[0].Id' --output text | sed 's|/hostedzone/||')"
CHANGE_BATCH="$(printf '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"%s","Type":"A","AliasTarget":{"HostedZoneId":"%s","DNSName":"%s","EvaluateTargetHealth":true}}}]}' "$HOST_NAME" "$ALB_ZONE_ID" "$ALB_DNS")"
aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" --change-batch "$CHANGE_BATCH" >/dev/null

printf 'configured https://%s -> %s:%s\n' "$HOST_NAME" "$TARGET_PRIVATE_IP" "$TARGET_PORT"
REMOTE_AWS
