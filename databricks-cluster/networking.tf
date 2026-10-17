resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.resource_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
  tags                = local.global_tags
}

resource "azurerm_subnet" "public_subnet" {
  name                 = "sub-public-${local.resource_prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  # Alterado de /24 para /22 para suportar o crescimento seguro do cluster Spark
  address_prefixes     = ["10.0.4.0/22"] 

  delegation {
    name = "databricks-del-public"
    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "sub-private-${local.resource_prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  # Alterado de /24 para /22 para garantir IPs suficientes para os nós Workers privados
  address_prefixes     = ["10.0.8.0/22"]

  delegation {
    name = "databricks-del-private"
    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"
      ]
    }
  }
}
