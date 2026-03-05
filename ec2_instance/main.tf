# =========================
# AMI Data Source
# =========================
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# =========================
# Default VPC
# =========================
data "aws_vpc" "default" {
  default = true
}

# =========================
# Default Security Group
# =========================
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

# =========================
# EC2 Instance
# =========================
resource "aws_instance" "t3_micro_ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = "hp-test"
  
  # Attach default security group automatically
  vpc_security_group_ids = [data.aws_security_group.default.id]

  tags = {
    Name = "t3-micro-ec2"
  }
}
