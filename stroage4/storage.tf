resource "azurerm_storage_account" "new-sa" {
  name                     = "${random_string.locals.id}"
  resource_group_name      = azurerm_resource_group.storage.name
  location                 = azurerm_resource_group.storage.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

}
resource "azurerm_storage_container" "backend" {
  name                     = "terraformstatefile"
  storage_account_name     = "${azurerm_storage_account.new-sa.name}"
}