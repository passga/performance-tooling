
output "aws_vpc_id" {
  value = aws_vpc.main.id
}

output "aws_subnet_id" {
  value = aws_subnet.public.id
}

output "aws_sg_id" {
  value = aws_security_group.main.id
}
