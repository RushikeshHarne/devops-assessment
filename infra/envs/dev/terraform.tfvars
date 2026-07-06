env        = "dev"
aws_region = "ap-south-1"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
availability_zones   = ["ap-south-1a", "ap-south-1b"]

container_image   = "nginx:alpine"
app_port          = 80
ecs_task_cpu      = 256
ecs_task_memory   = 512
ecs_desired_count = 1

db_name     = "appdb"
db_username = "appuser"
# db_password is passed via TF_VAR_db_password env variable

rds_instance_class          = "db.t3.micro"
rds_allocated_storage       = 20
rds_deletion_protection     = false
rds_skip_final_snapshot     = true
rds_backup_retention_period = 3
