resource "aws_security_group" "ec2" {
  name        = "${var.name}-ec2-sg"
  description = "Hudaayah backend EC2 security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-ec2-sg" })
}

# HTTP — public by default (TLS can terminate here or upstream later).
resource "aws_security_group_rule" "http_in" {
  count             = length(var.http_ingress_cidrs) > 0 ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.ec2.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.http_ingress_cidrs
  description       = "HTTP"
}

# HTTPS.
resource "aws_security_group_rule" "https_in" {
  count             = length(var.https_ingress_cidrs) > 0 ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.ec2.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.https_ingress_cidrs
  description       = "HTTPS"
}

# App port 8000 — direct access to the Django/gunicorn container.
resource "aws_security_group_rule" "app_in" {
  count             = length(var.app_ingress_cidrs) > 0 ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.ec2.id
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = var.app_ingress_cidrs
  description       = "Django app (8000)"
}

# SSH — only if explicitly allow-listed. SSM Session Manager is preferred.
resource "aws_security_group_rule" "ssh_in" {
  count             = length(var.ssh_ingress_cidrs) > 0 ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.ec2.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_ingress_cidrs
  description       = "SSH (restricted)"
}

resource "aws_security_group_rule" "all_out" {
  type              = "egress"
  security_group_id = aws_security_group.ec2.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound"
}
