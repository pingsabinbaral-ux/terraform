provider "aws" {
  region = "us-east-2"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

module "ec2_instance" {
  source        = "./ec2-module"
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  name          = "MyModuleEC2"
}
