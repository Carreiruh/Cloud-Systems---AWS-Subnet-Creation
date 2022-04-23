variable "region" {
  type    = string
  default = "us-east-1"
}

variable "ami" {
  default     = "ami-07eaf2ea4b73a54f6"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "project_tags" {
  type = map(any)
  default = {
    Name       = "MC-Test"
    Owner      = "MC"
    Purpose    = "Testing"
    CostCenter = "0001"
  }
}