#!/bin/bash

# Set AWS regions
PRIMARY_REGION="eu-west-1"      # Ireland
DR_REGION="eu-central-1"        # Frankfurt

echo "=== Verifying AWS Resources ==="
echo ""

# Check Primary Region (Ireland)
echo "=== PRIMARY REGION (Ireland, $PRIMARY_REGION) ==="

echo "1. ECS Clusters:"
aws ecs list-clusters --region $PRIMARY_REGION

echo ""
echo "2. ECS Services (assuming cluster name contains 'ecs-lampstack'):"
CLUSTERS=$(aws ecs list-clusters --region $PRIMARY_REGION --query 'clusterArns[*]' --output text)
for cluster in $CLUSTERS; do
  if [[ $cluster == *"ecs-lampstack"* ]]; then
    echo "Cluster: $cluster"
    aws ecs list-services --cluster $cluster --region $PRIMARY_REGION
  fi
done

echo ""
echo "3. RDS Instances:"
aws rds describe-db-instances --region $PRIMARY_REGION --query 'DBInstances[*].[DBInstanceIdentifier,Engine,DBInstanceStatus]' --output table

echo ""
echo "4. Parameter Store Secrets (for DB credentials):"
aws ssm describe-parameters --region $PRIMARY_REGION --parameter-filters "Key=Name,Values=/copilot/*/test/secrets/DB_*" --query 'Parameters[*].Name' --output table

echo ""
echo "5. CloudWatch Alarms for ECS CPU:"
aws cloudwatch describe-alarms --region $PRIMARY_REGION --query 'MetricAlarms[?MetricName==`CPUUtilization`].[AlarmName,StateValue]' --output table

echo ""
echo "=== DR REGION (Frankfurt, $DR_REGION) ==="

echo "1. ECS Clusters:"
aws ecs list-clusters --region $DR_REGION

echo ""
echo "2. RDS Read Replicas:"
aws rds describe-db-instances --region $DR_REGION --query 'DBInstances[?ReadReplicaSourceDBInstanceIdentifier!=null].[DBInstanceIdentifier,ReadReplicaSourceDBInstanceIdentifier,DBInstanceStatus]' --output table

echo ""
echo "3. Parameter Store Secrets (for DR):"
aws ssm describe-parameters --region $DR_REGION --parameter-filters "Key=Name,Values=/copilot/*/dr/secrets/DB_*" --query 'Parameters[*].Name' --output table

echo ""
echo "=== VERIFICATION COMPLETE ==="