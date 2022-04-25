resource "azurerm_resource_group" "project2" {
  location                                     = "eastus2"
  name                                         = "${var.PREFIX}-${var.ENV}"
}
resource "random_string" "locals" {
  length                                       = 16
  number                                       = false
  lower                                        = false
  upper                                        = false
  special                                      = false
  override_special                             = "-/@"

}

