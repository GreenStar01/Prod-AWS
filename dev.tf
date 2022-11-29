terraform {
    backend "remote" {
        organization = "DevOps"
        workspaces {
          name = "Demo-Practice"
        }
      
    }
    backend "s3" {
        bucket = "Dev-bucket"
        key = "web-app/terraform.tfstate"   #location where the state file will be saved
        region = "us-east-1"
        dynamodb_table = "terraform-state-locking"
        encrypt = true
      
    }
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 3.0 "
      }
    }

}
provider "aws"{
    region = "us-east-1 "
} 

resource "aws_dynamodb_table" "terraform_locks" {
    name ="terraform-state-locking"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"
    attribute {
      name = "LockID"
      type = "S"
    }

}

resource "aws_instance" "web-serv"{
    ami =   "ami-011899242bb902164"
    instance_type = "t2.micro"
    security_groups = [""]
    user_data = <<-EOF
            #!/bin/bash
            echo "Web-server-1" > index.html
            python3 -m http.server 8080 &

            EOF
    tags = {
      "Name" = "Dev-Web-serv1"
    }
}
resource "aws_instance" "web-serv-2"{
    ami =   "ami-011899242bb902164"
    instance_type = "t2.micro"
    security_groups = [""]
    user_data = <<-EOF
            #!/bin/bash
            echo "Web-server-2" > index.html
            python3 -m http.server 8080 &

            EOF
    tags = {
      "Name" = "Dev-Web-serv2"
    }
}

resource "aws_s3_bucket" "bucket"{

    bucket= "devops-demo-bucket"
    force_destroy = true
    versioning {
        enabled = true
        
    }
    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm ="AES256"
        }
      }
    }
}
#Referencing exisitng resource
data "aws_vpc" "default_vpc"{  
    default = true
}
data "aws_subnet" "default_subnet" {
    vpc_id = data.aws_vpc.default_vpc
  
}

#You can either use Inline security group or the aws security group rule
resource "aws_security_group" "instances"{
    name = "instance-security-group"
}
resource "aws_security_group_rule" "allow_http_inbound"{
    type = "ingress"
    security_group_id = aws_security_group.instances.id
    
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

}

resource "aws_lb_listener" "http"{
    load_balancer_arn = aws_lb.load_balancer.arn
    port = 80
    protocol = "HTTP"

    default_action {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = "404: page not found"
        status_code =  404
      }
      
    }

}

resource "aws_lb_target_group" "instances" {
    name = "web-target-group"
    port = 8080
    protocol = "HTTP"
    vpc_id = data.aws-vpc.default_vpc.in

    health_check {
      path = "/"
      protocol = "HTTP"
      interval = 15
      timeout = 3
      healthy_threshold = 2
      unhealthy_threshold = 2
    }
  
}

resource "aws_lb_target_group_attachment" "web-serv"{
    target_group_arn = aws_lb_target_group.instances.id
    target_id = aws_instance.web-serv
    port = 8080
}

resource "aws_lb_target_group_attachment" "web-serv2"{
    target_group_arn = aws_lb_target_group.instances.arn
    target_id = aws_instance.web-serv-2
    target_port = 8080
}

resource "aws_lb_listener_rule" "instances" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
        path_pattern {
            values = ["*"]
        }
    }

    action {
      
      type = "forward"
      target_group_arn = aws_lb_target_group.instances.arn
    }
  
}      

resource "aws_security_group" "alb" {
    name = "alb-security-group"
  
}

resource "aws_security_group_rule" "alb_inbound" {
    type = "ingress"
    security_group_id = aws_security_group.alb.id

    from_port = 80
    to_port  = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

}
resource "aws_security_group-rule" "alb_outbound" {
    type = "egress"
    security_group_id = aws_security_group.alb.id
    
    from_port = 0
    to_port = 0
    protocol "-1"
    cidr_block = ["0.0.0.0/0"]
    
}

resource "aws_lb" "load_balancer"{
    name = "web-app-lb"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default_subnet.ids
    security_groups = [aws_security_group.alb.id]
}

resource "aws_route53_zone" "primary"{
    name = "greenstar01.com"

}

resource "aws_route53_record" "root" {
    zone_id = aws_route53_zone.primary.zone_id
    name = "greenstar01.com"
    type = "A"

    alias   {
        name = aws_lb.load_balancer.dns_name
        zone_id = aws_lb.load_balancer.zone_id
        evaluate_target_health = true
    }
}        

resource "aws-db_instance" "db_instance" {
    allocated_storage =20
    storage-type = "standard"
    engine = "postgres"
    engine_version = "12.5"
    instance_class = "db.t2.micro"
    name = "mydb"
    username = "foo"
    password = "foobarbaz"
    skip-final_snapshot = true
}                                                                                                                       =]