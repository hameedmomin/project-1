resource "azurerm_subnet" "websubnets" {
  name                           = "${azurerm_virtual_network.vnet.name}-${var.web}"
  resource_group_name            = azurerm_resource_group.project2.name
  virtual_network_name           = azurerm_virtual_network.vnet.name
  address_prefixes               = ["10.0.1.0/24"]
}
resource "azurerm_network_security_group" "nsg" {
  name                = "${azurerm_subnet.websubnets.name}-nsg"
  depends_on          = [azurerm_subnet.websubnets]
  location            = azurerm_resource_group.project2.location
  resource_group_name = azurerm_resource_group.project2.name

}
resource "azurerm_subnet_network_security_group_association" "websubnet-nsg-association" {
  depends_on                = [azurerm_network_security_rule.nsg-rule] # Every NSG Rule Association will disassociate NSG from Subnet and Associate it, so we associate it only after NSG is completely created - Azure Provider Bug https://github.com/terraform-providers/terraform-provider-azurerm/issues/354
  subnet_id                 = azurerm_subnet.websubnets.id
  network_security_group_id = azurerm_network_security_group.nsg.id

}

locals {
  web_inbound_ports_maps = {
    "100" : "80", # If the key starts with a number, you must use the colon syntax ":" instead of "="
    "110" : "443",
    "120" : "22"
  }
}
resource "azurerm_network_security_rule" "nsg-rule" {
  for_each                    = local.web_inbound_ports_maps
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "Rule-port-${each.value}"
  network_security_group_name = azurerm_network_security_group.nsg.name
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  destination_port_range      = each.value
  priority                    = each.key
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.project2.name

}