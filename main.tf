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