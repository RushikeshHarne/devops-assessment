variable "env"               { 
  type = string
}
variable "vpc_id"            { 
  type = string
}
variable "public_subnet_ids" { 
  type = list(string) 
}
variable "private_subnet_ids"{ 
type = list(string)
}
variable "alb_sg_id"         { type = string }
variable "ecs_sg_id"         { type = string }
variable "aws_region"        { type = string }
variable "container_image"   { type = string }
variable "app_port"          {
  type = number
  default = 80 
}
variable "task_cpu"          { type = number }
variable "task_memory"       { type = number }
variable "desired_count"     { type = number }
variable "db_host"           { type = string }
variable "db_name"           { type = string }
variable "health_check_path" { 
  type = string
  default = "/" 
}
variable "log_retention_days"{
  type = number
  default = 7 
}
