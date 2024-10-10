terraform {
  required_providers {
    dotenv = {
      source  = "germanbrew/dotenv"
      version = "1.0.0" # Adjust to the latest version
    }
  }
  required_version = ">= 1.0"
}
data "dotenv" "app" {
  filename = ".env"
}

# locals {
  # aws_access_key = data.dotenv_file.env_vars.vars["AWS_ACCESS_KEY_ID"]
  # aws_secret_key = data.dotenv_file.env_vars.vars["AWS_SECRET_ACCESS_KEY"]
#   aws_region     = data.dotenv.env.vars["AWS_REGION"]
#   aws_user_arn     = data.dotenv.env.vars["AWS_USER_ARN"]
# }

# provider "aws" {
#   access_key = local.aws_access_key
#   secret_key = local.aws_secret_key
# #   region     = local.aws_region
#   user_arn   = local.aws_user_arn
# }

provider "dotenv" {}
resource "aws_subnet" "kobi_subnet" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_1
  availability_zone = var.availability_zone
  tags = {
    Name = "kobi-subnet"
  }
}

resource "aws_subnet" "kobi_subnet_2" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_2
  availability_zone = var.availability_zone
  tags = {
    Name = "kobi-subnet-2"
  }
}

resource "aws_route_table" "kobi_route_table" {
  vpc_id = var.vpc_id
  tags = {
    Name = "kobi-route-table"
  }
}

resource "aws_route_table_association" "kobi_route_table_association_1" {
  subnet_id      = aws_subnet.kobi_subnet.id
  route_table_id = aws_route_table.kobi_route_table.id
}

resource "aws_route_table_association" "kobi_route_table_association_2" {
  subnet_id      = aws_subnet.kobi_subnet_2.id
  route_table_id = aws_route_table.kobi_route_table.id
}
resource "aws_route" "kobi_route_to_nat_gateway" {
  route_table_id         = aws_route_table.kobi_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "nat-0440e3c0e49d26497" 
}

resource "aws_s3_bucket_policy" "workshop_bucket_policy" {
  bucket = "kobi-k-bukcet" 

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowUserAccess"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::730335218716:user/kobi-user"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::kobi-k-bukcet/*" 
      }
    ]
  })
}
