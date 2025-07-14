import boto3

REGION = "eu-central-1"  # DR region
REPLICA_IDENTIFIER = "<your-rds-replica-identifier>"  # Read replica ID
PARAM_NAME = "<your_db_host_parameter_store_value>"

CLUSTER_NAME = "<your-ecs-cluster"
SERVICE_NAME = "<your-ecs-cluster-service"


def lambda_handler(event, context):
    rds = boto3.client("rds", region_name=REGION)
    ssm = boto3.client("ssm", region_name=REGION)
    ecs = boto3.client("ecs", region_name=REGION)

    # Promote the RDS read replica
    print("🔄 Promoting read replica...")
    rds.promote_read_replica(DBInstanceIdentifier=REPLICA_IDENTIFIER)

    # Wait until the DB is available
    print("⏳ Waiting for DB instance to become available...")
    waiter = rds.get_waiter("db_instance_available")
    waiter.wait(DBInstanceIdentifier=REPLICA_IDENTIFIER)

    # Fetch the new DB endpoint
    db_info = rds.describe_db_instances(DBInstanceIdentifier=REPLICA_IDENTIFIER)
    new_host = db_info["DBInstances"][0]["Endpoint"]["Address"]
    print(f"✅ New RDS host: {new_host}")

    # Update the SSM Parameter Store
    print("💾 Updating DB_HOST in Parameter Store...")
    ssm.put_parameter(Name=PARAM_NAME, Value=new_host, Overwrite=True, Type="String")

    # Force new deployment of ECS service to pick up updated env vars
    print("🔁 Forcing ECS service deployment...")
    ecs.update_service(
        cluster=CLUSTER_NAME, service=SERVICE_NAME, forceNewDeployment=True
    )

    print("🎉 Failover complete and ECS redeployed.")

    return {"statusCode": 200, "body": f"Failover complete. New DB_HOST: {new_host}"}
