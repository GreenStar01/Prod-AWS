provider "aws"{
    region = "us-east-1"
    access_key = "AKIAR4EREHREPRV6NA75"
    secret_key = "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"
}


resource "aws_vpc" "prod-vpc"{
    cidr_block = "10.0.0.0/16"
    tags = {

        Name = "production"
    }
}

resource "aws_internet_gateway" "prod-gw"{
        vpc_id = aws_vpc.prod-vpc.id

}

resource "aws_route_table" "prod-RT"{
    vpc_id = aws_vpc.prod-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.prod-gw.id
    }

    route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.prod-gw.id
  }

    tags = {
        Name = "Prod-Route_table"
    }
}

resource "aws_subnet" "prod-public-subnet"{

    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "Prod-Subnet"
    }
}

resource "aws_route_table_association" "prod-assc" {

    subnet_id = aws_subnet.prod-public-subnet.id
    route_table_id = aws_route_table.prod-RT.id
  
}

resource "aws_security_group" "prod-web_inbound" {
    name = "allow_web_traffic"
    description = "Allow Inboud Web Traffic"
    vpc_id = aws_vpc.prod-vpc.id

    ingress {
    description = "Allow SSH Traffic"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  ###
    }

    ingress {
    description = "Allow HTTP Traffic"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  ###
    }

    ingress {
    description = "Allow HTTPS Traffic"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  ###
    }

    egress {

        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "Allow-web-traffic"
    }
}

resource "aws_network_interface" "prod-nic" {
    subnet_id = aws_subnet.prod-public-subnet.id
    private_ips = ["10.0.1.50"]
    security_groups = [aws_security_group.prod-web_inbound.id]
}

resource "aws_eip" "prod-eip"{
    vpc = true
    network_interface = aws_network_interface.prod-nic.id
    associate_with_private_ip =  "10.0.1.50"
    depends_on = [ aws_internet_gateway.prod-gw ]
}

resource "aws_instance" "Prod-web"{

    ami = "ami-026b57f3c383c2eec"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    network_interface {
      device_index = 0
        network_interface_id = aws_network_interface.prod-nic.id
    }
   
    
    key_name = "DemoKP"

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c "echo Your Web Server Works > /var/www/html/index.html"

                EOF
    tags = {
        Name = "Web-server"
    }
}