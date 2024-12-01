output "kobi_subnet_id_1" {
  value = aws_subnet.kobi_subnet.id
}

output "kobi_subnet_id_2" {
  value = aws_subnet.kobi_subnet_2.id
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
# s