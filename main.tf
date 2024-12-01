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


resource "aws_subnet" "kobi_subnet" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_1
  availability_zone = var.availability_zone_1
  tags = {
    Name = "kobi-subnet"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_subnet" "kobi_subnet_2" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_2
  availability_zone = var.availability_zone_2
  tags = {
    Name = "kobi-subnet-2"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
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

  cluster_name    = var.cluster_name
  cluster_version = "1.29"
  cluster_endpoint_public_access  = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
     aws-ebs-csi-driver = {
       addon_version = "v1.35.0-eksbuild.1"
     }
    coredns = {
       addon_version = "v1.11.1-eksbuild.4"
     }
   }

  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.kobi_subnet.id, aws_subnet.kobi_subnet_2.id] 

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
    Name = "Kobi_cluster"
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "aws_security_group" "ssh_access" {
  name        = "kobi-ssh_access"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH ingress from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kobi-ssh_access"
  }
}

module "lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "kubernetes_service_account" "service-account" {
  metadata {
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
        "app.kubernetes.io/component": "controller"
        "app.kubernetes.io/name": "aws-load-balancer-controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.lb_role.iam_role_arn
    }
  }
}

resource "aws_ecr_repository" "kobi-2048" {
  name = "kobi-2048"
}

resource "kubernetes_deployment" "example" {
  metadata {
    name = "example-deployment-kobi"
    labels = {
      app = "example-kobi"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "example-kobi"
      }
    }

    template {
      metadata {
        labels = {
          app = "example-kobi"
        }
      }

      spec {
        container {
          image = "../2048/Dockerfile"
          name  = "example"

          port {
            container_port = 80
          }
        }
      }
    }
  }

  depends_on = [module.eks]
}

resource "kubernetes_service" "example" {
  metadata {
    name = "example-service-kobi"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"            = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
      "service.beta.kubernetes.io/aws-load-balancer-ssl-cert"        = var.acm_certificate_arn
      "service.beta.kubernetes.io/aws-load-balancer-ssl-ports"       = "443"
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "http"
    }
  }

  spec {
    selector = {
      app = kubernetes_deployment.example.metadata[0].labels.app
    }

    port {
      port        = 443
      target_port = 80
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.example]
}