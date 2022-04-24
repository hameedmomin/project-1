resource "azurerm_network_interface" "nic" {
  name                = "vm-nic"
  location            = azurerm_resource_group.project2.location
  resource_group_name = azurerm_resource_group.project2.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.websubnets.id
    private_ip_address_allocation = "Dynamic"
  }
}