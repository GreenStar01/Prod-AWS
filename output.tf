output "webserv-1-ip"{
    value = aws_instance.web-serv.public_ip

}

output "webserv-2-ip"{
    value = aws_instance.web-serv-2.public_ip
}

