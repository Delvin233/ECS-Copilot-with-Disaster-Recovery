# 🔐 Highly Available LAMP Stack on Amazon ECS with Disaster Recovery

A PHP visit counter application deployed on **Amazon ECS Fargate** using **AWS Copilot** with **Disaster Recovery (DR)** capabilities across multiple AWS regions.

## Current Status

- ✅ PHP visit counter application (`index.php`)
- ✅ Docker containerization (`Dockerfile.app`)
- ✅ ECS deployment with AWS Copilot
- ✅ SSM Parameter Store integration for secrets
- 🚧 RDS database integration (in progress)
- 🚧 Cross-region disaster recovery setup (planned)

---

## 🧱 Architecture Overview

### 🌍 Primary Region

- **ECS Fargate**: Hosts containerized PHP visit counter app
- **RDS MySQL**: Primary database for visit tracking
- **Application Load Balancer**: Routes traffic to ECS tasks
- **SSM Parameter Store**: Securely stores database credentials
- **CloudWatch**: Monitors application and infrastructure metrics

### 🆘 Disaster Recovery (DR) Region (Planned)

- **ECS (Pilot Light)**: Service deployed with `count: 0` (activated during DR)
- **RDS Read Replica**: Cross-region replica of primary database
- **Lambda Function**: Automates DR failover process
- **CloudWatch Alarms**: Triggers DR automation on primary region failure
- **SNS**: Notification system for DR events

---

## 🚀 Deployment Guide

### 1. Prerequisites

- AWS CLI configured
- Docker installed
- AWS Copilot CLI installed

### 2. Initialize Copilot Application

```bash
copilot app init
copilot env init --name test --region <primary-region>
copilot env deploy --name test
```

### 3. Deploy Service

```bash
copilot svc init --name <service-name> --svc-type "Load Balanced Web Service"
copilot svc deploy --name <service-name> --env test
```

### 4. Configure Database Secrets

Create parameters in **AWS Systems Manager Parameter Store**:

```bash
# Database credentials (replace with actual values)
aws ssm put-parameter --name "/copilot/<service-name>/test/secrets/DB_HOST" --value "<rds-endpoint>" --type "String"
aws ssm put-parameter --name "/copilot/<service-name>/test/secrets/DB_USER" --value "<username>" --type "String"
aws ssm put-parameter --name "/copilot/<service-name>/test/secrets/DB_PASS" --value "<password>" --type "SecureString"
aws ssm put-parameter --name "/copilot/<service-name>/test/secrets/DB_NAME" --value "<database-name>" --type "String"
```

### 5. Service Manifest Configuration

```yaml
environments:
  test:
    secrets:
      DB_HOST: /copilot/<service-name>/test/secrets/DB_HOST
      DB_USER: /copilot/<service-name>/test/secrets/DB_USER
      DB_PASS: /copilot/<service-name>/test/secrets/DB_PASS
      DB_NAME: /copilot/<service-name>/test/secrets/DB_NAME
  dr:
    count: 0
    secrets:
      DB_HOST: /copilot/<service-name>/dr/secrets/DB_HOST
      DB_USER: /copilot/<service-name>/dr/secrets/DB_USER
      DB_PASS: /copilot/<service-name>/dr/secrets/DB_PASS
      DB_NAME: /copilot/<service-name>/dr/secrets/DB_NAME
```

---

## ⚙️ Disaster Recovery Automation

### DR Trigger Flow

1. **CloudWatch Alarm** detects RDS failure in primary region
2. **SNS Topic** sends notification to Lambda function in DR region
3. **Lambda Function** executes DR procedures:
   - Promotes RDS read replica to standalone instance
   - Updates Parameter Store with new database endpoint
   - Scales ECS service from `count: 0` to `count: 1`
   - Sends notification of DR activation

### Lambda DR Function (Python)

```python
import boto3
import json

def lambda_handler(event, context):
    rds = boto3.client('rds', region_name='<dr-region>')
    ssm = boto3.client('ssm', region_name='<dr-region>')
    ecs = boto3.client('ecs', region_name='<dr-region>')
    
    # Promote read replica
    rds.promote_read_replica(DBInstanceIdentifier='<replica-id>')
    
    # Wait for promotion to complete
    waiter = rds.get_waiter('db_instance_available')
    waiter.wait(DBInstanceIdentifier='<replica-id>')
    
    # Get new endpoint
    response = rds.describe_db_instances(DBInstanceIdentifier='<replica-id>')
    new_endpoint = response['DBInstances'][0]['Endpoint']['Address']
    
    # Update Parameter Store
    ssm.put_parameter(
        Name='/copilot/<service-name>/dr/secrets/DB_HOST',
        Value=new_endpoint,
        Overwrite=True,
        Type='String'
    )
    
    # Scale ECS service
    ecs.update_service(
        cluster='<cluster-name>',
        service='<service-name>',
        desiredCount=1
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('DR activation completed')
    }
```

---

## 🔐 Security Best Practices

- ✅ **No hardcoded credentials** - All secrets stored in SSM Parameter Store
- ✅ **Least privilege IAM roles** for ECS tasks and Lambda functions
- ✅ **VPC security groups** restrict database access to ECS tasks only
- ✅ **Encrypted storage** for RDS and Parameter Store SecureString values
- ✅ **Private subnets** for database and application tiers
- ✅ **Public repository safe** - No sensitive information exposed

---

## 📦 Project Structure

```
.
├── Dockerfile.app          # Container configuration
├── index.php              # PHP visit counter application
├── README.md              # Project documentation
├── .gitignore            # Git ignore rules
└── copilot/              # AWS Copilot configurations (gitignored)
    ├── environments/
    └── <service-name>/
        └── manifest.yml
```

---

## 🔁 Future Enhancements

- [ ] **Route 53 Health Checks** for automatic DNS failover
- [ ] **S3 Cross-Region Replication** for static assets
- [ ] **CloudWatch Dashboards** for monitoring
- [ ] **Automated testing** of DR procedures
- [ ] **Multi-AZ RDS deployment** for high availability
- [ ] **Auto Scaling** based on CPU/memory metrics

---

## 🧪 Testing Disaster Recovery

### Manual DR Test

1. **Simulate primary region failure**:
   ```bash
   # Stop RDS instance in primary region
   aws rds stop-db-instance --db-instance-identifier <primary-db-id>
   ```

2. **Monitor CloudWatch alarms** and Lambda execution

3. **Verify DR activation**:
   ```bash
   # Check ECS service in DR region
   copilot svc show --name <service-name> --env dr
   ```

4. **Test application** using DR region load balancer URL

### Automated Testing

- Set up CloudWatch synthetic canaries
- Create automated DR drills using AWS Systems Manager
- Implement RTO/RPO monitoring and alerting

---

## 📊 Monitoring and Observability

- **CloudWatch Metrics**: ECS task health, RDS performance
- **CloudWatch Logs**: Application logs and Lambda execution logs  
- **CloudWatch Alarms**: Database connectivity, high latency, error rates
- **AWS X-Ray**: Distributed tracing (optional)

---

## 🚨 Recovery Objectives

- **RTO (Recovery Time Objective)**: < 15 minutes
- **RPO (Recovery Point Objective)**: < 5 minutes
- **Availability Target**: 99.9% uptime