variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "cluster_name" {
  description = "cluster Name"
  type        = string
  default     = "hori"
}

variable "hosted_zone_id" {
  description = "Hosted Zone Id"
  type        = string  
}

variable "mysql_password" {
  description = "MySQL Password"
  type        = string  
}