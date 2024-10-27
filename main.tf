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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "Kobi-cluster"
  cluster_version = "1.29"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns   = {
      addon_version            = "v1.11.3-eksbuild.1"
    }
     aws-ebs-csi-driver = {}

  }

  vpc_id                   = var.vpc_id
  subnet_ids               = [aws_subnet.kobi_subnet.id, aws_subnet.kobi_subnet.id-2]
  control_plane_subnet_ids = [aws_subnet.kobi_subnet.id, aws_subnet.kobi_subnet.id-2]

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    example = {
      instance_types = ["t2.small"]

      min_size     = 2
      max_size     = 10
      desired_size = 2
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    # One access entry with a policy associated
    example = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::730335218716:user/kobi-user"

      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            namespaces = ["default"]
            type       = "namespace"
          }
        }
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
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