provider "aws" {
  region = var.aws_region
}   

resource "aws_instance" "name" {
   ami = var.ami_id
   instance_type = var.instance_type    
   key_name = var.key_name
   vpc_security_group_ids = var.security_group_ids
   
   tags = {
     Name = var.instance_name
   }
}

