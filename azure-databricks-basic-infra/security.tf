# ==============================================================================
# 1. GRUPO DE SEGURANÇA DE REDE (NSG)
# ==============================================================================
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.global_tags
}

# ==============================================================================
# 2. REGRAS DE SEGURANÇA INTERNAS (Exemplo de controle de tráfego)
# ==============================================================================
resource "azurerm_network_security_rule" "allow_databricks_internal" {
  name                        = "allow-databricks-worker-to-worker"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# ==============================================================================
# 3. ASSOCIAÇÕES OBRIGATÓRIAS (Blindadas com Lifecycle)
# ==============================================================================
resource "azurerm_subnet_network_security_group_association" "public_assoc" {
  subnet_id                 = azurerm_subnet.public_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  # 🚀 Impede travamentos no WSL e elimina a necessidade de imports manuais
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_subnet_network_security_group_association" "private_assoc" {
  subnet_id                 = azurerm_subnet.private_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  # 🚀 Impede travamentos no WSL e elimina a necessidade de imports manuais
  lifecycle {
    create_before_destroy = true
  }
}
