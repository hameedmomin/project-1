resource "azurerm_resource_group" "storage" {
  location                 = "eastus"
  name                     = "newstorage"
}

resource "random_string" "locals" {
  length                                       = 16
  lower                                        = false
  upper                                        = false
  special                                      = false
  override_special                             = "-/@"

}
