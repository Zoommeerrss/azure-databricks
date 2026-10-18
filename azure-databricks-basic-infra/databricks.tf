# ==============================================================================
# 1. DATABRICKS WORKSPACE (Premium SKU para suporte ao Unity Catalog)
# ==============================================================================
resource "azurerm_databricks_workspace" "db_workspace" {
  name                = "dbw-${local.resource_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium"

  # Nome dinâmico exclusivo por ambiente para evitar conflitos na Azure
  managed_resource_group_name = "rg-managed-${local.resource_prefix}"

  custom_parameters {
    no_public_ip        = true
    virtual_network_id  = azurerm_virtual_network.vnet.id
    
    public_subnet_name                                  = azurerm_subnet.public_subnet.name
    public_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.public_assoc.id 
    
    private_subnet_name                                 = azurerm_subnet.private_subnet.name
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private_assoc.id 
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.public_assoc,
    azurerm_subnet_network_security_group_association.private_assoc
  ]

  tags = local.global_tags
}
