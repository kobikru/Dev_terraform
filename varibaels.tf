variable "vpc_id" {
  description = "The ID of the VPC where the subnet will be created"
  type        = string
  default     = "vpc-01b834daa2d67cdaa"
}

variable "subnet_cidr_1" {
  description = "The CIDR bslock for the subnet"
  type        = string
  default     = "192.168.14.0/24"
}
variable "subnet_cidr_2" {
  description = "The CIDR block for the subnet"
  type        = string
  default     = "192.168.15.0/24"
}

variable "availability_zone" {
  description = "The availability zone where the subnet will be created"
  type        = string
  default     = "eu-west-1a"
}