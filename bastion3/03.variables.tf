variable "ENV"    {
  default        = "dev"
}
variable "PREFIX" {
  default        = "IT"
}
variable "vnet" {
  type           = list(string)
  default        = ["10.0.0.0/16"]
}
variable "web" {
  type           = string
  default        = "websubnets"
}
variable "subnet_address" {
  type           = list(string)
  default        = ["10.0.1.0/24"]
}

variable "app" {
  default        = "appsubnet"
  type           = string
}
variable "app_address" {
  type           = list(string)
  default        = ["10.0.11.0/24"]
}
variable "db" {
  default        = "dbsubnet"
  type           = string
}
variable "db_address" {
  type           = list(string)
  default        = ["10.0.21.0/24"]
}
variable "bastion" {
  default        = "bastionsubnet"
  type           = string
}
variable "bastion_address" {
  type           = list(string)
  default        = ["10.0.100.0/24"]
}


