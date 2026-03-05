
variable "ami_id" {
  description = "AMI ID for the instance"
  default = "ami-04b4f1a9cf54c11d0"
}

variable "instance_type" {
  description = "Type of instance to launch"
  default = "t2.micro"
}

variable "key_name" {
  description = "Name of the key pair"
  default = "my-key-pair"
}       

variable "security_group_ids" {
  description = "List of security group IDs"
  default = ["sg-0abc1234def567890"]
}

variable "instance_name" {
  description = "Name tag for the instance"
  default = "MyInstance"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  default = "us-east-1"
}