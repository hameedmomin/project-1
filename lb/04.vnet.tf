resource "azurerm_virtual_network" "vnet" {
  name                            = "${var.PREFIX}-${var.ENV}-vnet"
  location                        = azurerm_resource_group.project2.location
  resource_group_name             = azurerm_resource_group.project2.name
  address_space                   = var.vnet
}