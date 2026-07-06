env        = "prod"
aws_region = "ap-south-1"

vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
availability_zones   = ["ap-south-1a", "ap-south-1b"]

container_image   = "nginx:alpine"
app_port          = 80
ecs_task_cpu      = 1024
ecs_task_memory   = 2048
ecs_desired_count = 2

db_name     = "appdb"
db_username = "appuser"
# db_password is passed via TF_VAR_db_password env variable

rds_instance_class          = "db.t3.medium"
rds_allocated_storage       = 100
rds_deletion_protection     = true
rds_skip_final_snapshot     = false
rds_backup_retention_period = 14
