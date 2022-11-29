variable "ami" {
    description = "EC-2 Instance Large Compute"
    type = string
    default = "ami-026b57f3c383c2eec"
}


variable "instance_type" {
    description = "large compute instance"
    type = string
    default = "t2.micro"

}

variable "bucket_name" {
    description ="name of s3 bucket"
    type = string
    
}

variable "db-name"{
    description = "DB Name"
    type    = string
}
variable "db_user" {
    description = "webdb-username"
    type = string 
    default = "webdb"

}

variable "db-pass"{
    type = string
    sensitive = true
    description = "password for DB"
}

variable "domain" {
    description = "Domain for website"
    type = string
}