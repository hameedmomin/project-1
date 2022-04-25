resource "azurerm_public_ip" "bastion-publicip" {
  name                = "${var.bastion-publicip}"
  resource_group_name = azurerm_resource_group.project2.name
  location            = azurerm_resource_group.project2.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "bastion-host-nic" {
  location            = azurerm_resource_group.project2.location
  name                = "${var.bastion-host-name}"
  resource_group_name = azurerm_resource_group.project2.name
  ip_configuration {
    name                          = "bastion-host-ip1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion-publicip.id
    subnet_id                     = azurerm_subnet.bastion.id

  }
}
#Azure linux VM for Bastion Host

resource "azurerm_linux_virtual_machine" "bastion_host_linuxvm" {
  name                            = "bastion-linuxvm"
  #computer_name                  = "bastionlinux-vm"  # Hostname of the VM (Optional)
  resource_group_name             = azurerm_resource_group.project2.name
  location                        = azurerm_resource_group.project2.location
  size                            = "Standard_DS1_v2"
  admin_username                  = "azureuser"
  network_interface_ids           = [ azurerm_network_interface.bastion-host-nic.id ]
  admin_ssh_key {
    username                      = "azureuser"
    public_key                    = file("${path.module}/.gitignore/ssh-key/.ssh.pub")
  }
  os_disk {
    caching                       = "ReadWrite"
    storage_account_type          = "Standard_LRS"
  }
  source_image_reference {
    publisher                     = "RedHat"
    offer                         = "RHEL"
    sku                           = "83-gen2"
    version                       = "latest"
  }
}