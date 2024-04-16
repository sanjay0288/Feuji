module "label_vpc" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  context    = module.base_label.context
  name       = "vpc"
  attributes = ["main"]
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = module.label_vpc.tags
}

# Create your subnets here
module "subnets" {
  source          = "hashicorp/subnets/cidr"
  base_cidr_block = var.vpc_cidr
  networks = [
    {
      name     = "public"
      new_bits = 8
    },
    {
      name     = "private"
      new_bits = 8
    }
  ]
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = module.subnets.network_cidr_blocks["public"]
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = module.subnets.network_cidr_blocks["private"]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id     = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = module.label_vpc.tags
}
