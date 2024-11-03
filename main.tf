
resource "aws_subnet" "kobi_subnet" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_1
  availability_zone = var.availability_zone_1
  tags = {
    Name = "kobi-subnet"
  }
}

resource "aws_subnet" "kobi_subnet_2" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_2
  availability_zone = var.availability_zone_
  tags = {
    Name = "kobi-subnet-2"
  }
}

resource "aws_route_table" "kobi_route" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "nat-0440e3c0e49d26497"
  }
}
resource "aws_route_table_association" "kobi_cidr_association_b" {  
  subnet_id      = aws_subnet.kobi_subnet.id
  route_table_id = aws_route_table.kobi_route.id
}  
resource "aws_route_table_association" "kobi_cidr_association_a" {  
  subnet_id      = aws_subnet.kobi_subnet_2.id
  route_table_id = aws_route_table.kobi_route.id
} 

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "my-cluster"
  cluster_version = "1.29"
  cluster_endpoint_public_access  = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
     aws-ebs-csi-driver = {
       addon_version            = "v1.35.0-eksbuild.1"
     }
    coredns = {
       addon_version            = "v1.11.1-eksbuild.4"
     }
   }


  vpc_id  = var.vpc_id
  subnet_ids  = [aws_subnet.kobi_subnet.id, aws_subnet.kobi_subnet_2.id] # Corrected


  eks_managed_node_groups = {
    example = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t2.small"]
      min_size       = 2
      max_size       = 10
      desired_size   = 2
    }
  }

  tags = {
    Name ="Kobi_cluster"
    Environment = "dev"
    Terraform   = "true"
  }
}

output "kobi_subnet_id_1" {
  value = aws_subnet.kobi_subnet.id
}

output "kobi_subnet_id_2" {
  value = aws_subnet.kobi_subnet_2.id
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}