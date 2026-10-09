provider "aws" {
    region = "us-east-2"
}

resource "aws_instance" "my_ec2" {
    ami = "ami-xxxxxxxxxxxxxx"
    instance_type = "t3.micro"
    tags = {
        Name = "MyFirstTerraformEC2"
    }
}
