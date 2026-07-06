variable "env"        { 
  type = string
  default = "prod"
}
variable "aws_region" { 
  type = string
  default = "ap-south-1" 
}

variable "vpc_cidr"             { type = string }
variable "public_subnet_cidrs"  { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "availability_zones"   { type = list(string) }

variable "app_port"         {
  type = number
  default = 80
}
variable "container_image"  { type = string }

variable "ecs_task_cpu"     { type = number }
variable "ecs_task_memory"  { type = number }
variable "ecs_desired_count"{ type = number }

variable "db_name"     { type = string }
variable "db_username" { type = string }
variable "db_password" { 
  type = string
  sensitive = true 
}

variable "rds_instance_class"          { type = string }
variable "rds_allocated_storage"       { type = number }
variable "rds_deletion_protection"     { type = bool }
variable "rds_skip_final_snapshot"     { type = bool }
variable "rds_backup_retention_period" { type = number }
