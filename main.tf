

resource "aws_iam_policy" "eks_access_policy" {
  name        = "eksAccessPolicy"
  path        = "/"
  description = "Policy to access EKS cluster"

  # Define what actions are allowed on which resources
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      }
    ]
  })
}

output "policy_arn" {
  value = aws_iam_policy.eks_access_policy.arn
}