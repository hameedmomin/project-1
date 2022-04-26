resource "azurerm_public_ip" "frontendip" {
  name                                            = "PublicIPForLB"
  location                                        = "West US"
  resource_group_name                             = azurerm_resource_group.project2.name
  allocation_method                               = "Static"
  sku                                             = "Standard"
}

resource "azurerm_lb" "weblb" {
  name                                            = "TestLoadBalancer"
  location                                        = azurerm_resource_group.project2.location
  resource_group_name                             = azurerm_resource_group.project2.name

  frontend_ip_configuration {
    name                                          = "frontendip"
    public_ip_address_id                          = azurerm_public_ip.frontendip.id
  }
}
resource "azurerm_lb_backend_address_pool" "lb-backend" {
  loadbalancer_id                                 = azurerm_lb.weblb.id
  name                                            = "BackEndAddressPool"

}
resource "azurerm_lb_probe" "lb-probe" {
  loadbalancer_id                                 = azurerm_lb.weblb.id
  name                                            = "lb-probe"
  port                                            = 80
  protocol                                        = "Tcp"
#  resource_group_name                             = azurerm_resource_group.project2.name
}

resource "azurerm_lb_rule" "lb-rule" {
  loadbalancer_id                                 = azurerm_lb.weblb.id
  name                                            = "LBRule"
  protocol                                        = "Tcp"
  frontend_port                                   = 80
  backend_port                                    = 80
  frontend_ip_configuration_name                  = azurerm_lb.weblb.frontend_ip_configuration[0].name
  backend_address_pool_ids                        = azurerm_lb_backend_address_pool.lb-backend.id
  probe_id                                        = azurerm_lb_probe.lb-probe.id
 # resource_group_name                             = azurerm_resource_group.project2.name

}

resource "azurerm_network_interface_backend_address_pool_association" "backend-association" {
  backend_address_pool_id                         = azurerm_lb_backend_address_pool.lb-backend.id
  ip_configuration_name                           = azurerm_network_interface.nic.ip_configuration[0].name
  network_interface_id                            = azurerm_network_interface.nic.id
}

