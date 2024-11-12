data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}


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
  availability_zone = var.availability_zone_2
  tags = {
    Name = "kobi-subnet-2"
  }
}

resource "aws_route_table" "kobi_route" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_id
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
  subnet_ids  = [aws_subnet.kobi_subnet.id, aws_subnet.kobi_subnet_2.id] 


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

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = "my-cluster"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  depends_on = [module.eks]
}

resource "helm_release" "loadbalancer" {
  name       = "my-loadbalancer"
  chart      = "${path.module}/my-loadbalancer-chart"
  namespace  = "default"

  values = [
    file("${path.module}/loadbalancer-values.yaml")
  ]

  set {
    name  = "service.certArn"
    value = "arn:aws:acm:eu-west-1:730335218716:certificate/8f4eeeea-9a1d-443c-a8c8-4de7f8b19aec"
  }

  depends_on = [helm_release.aws_load_balancer_controller]
}

resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.load_balancer_controller_irsa_role.iam_role_arn
    }
  }
}

module "load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.0"

  role_name = "load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
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