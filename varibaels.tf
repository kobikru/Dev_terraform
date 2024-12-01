variable "region" {
  description = "AWS region"
  default     = "eu-west-1"
}


variable "cluster_name" {
  description = "Name of the EKS cluster"
  default     = "my-cluster"
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate to use for the LoadBalancer"
  default     = "arn:aws:acm:eu-west-1:730335218716:certificate/8f4eeeea-9a1d-443c-a8c8-4de7f8b19aec"
}
variable "vpc_id" {
  description = "The ID of the VPC"
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

variable "availability_zone_1" {
  description = "The availability zone where the subnet will be created"
  type        = string
  default     = "eu-west-1a"
}
variable "availability_zone_2" {
  description = "The availability zone where the subnet will be created"
  type        = string
  default     = "eu-west-1b"
}
variable "nat_gateway_id" {
  description = "The nat gateway id"
  type        = string
  default     = "nat-0440e3c0e49d26497"
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair"
  type        = string
  default     = "9a241da3-14f1-412c-8af1-3b8196054e1a"
}