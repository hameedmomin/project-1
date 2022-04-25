variable "bastion-host-name" {
  default      = "bastion-publicip"
  type         = string
}
variable "bastion-publicip" {
  default      = "bastion-frontip"
  type         = string
}