variable "env"                    { type = string }
variable "private_subnet_ids"     { type = list(string) }
variable "rds_sg_id"              { type = string }
variable "db_name"                { type = string }
variable "db_username"            { type = string }
variable "db_password"            { type = string; sensitive = true }
variable "instance_class"         { type = string }
variable "allocated_storage"      { type = number }
variable "multi_az"               { type = bool; default = false }
variable "deletion_protection"    { type = bool }
variable "skip_final_snapshot"    { type = bool }
variable "backup_retention_period"{ type = number }
