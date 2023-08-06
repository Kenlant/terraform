resource "random_id" "suffix" {
  byte_length = 4
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "proget_network" {
  name                = "proget-vnet-${random_id.suffix.id}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "proget_subnet" {
  name                 = "proget-subnet-${random_id.suffix.id}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.proget_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "proget_public_ip" {
  name                = "proget-ip-${random_id.suffix.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  domain_name_label   = var.domain_name
  tags                = var.tags
}

resource "azurerm_network_security_group" "proget_nsg" {
  name                = "proget-nsg-${random_id.suffix.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "proget_nic" {
  name                = "proget-nic-${random_id.suffix.id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "proget_nic_configuration-${random_id.suffix.id}"
    subnet_id                     = azurerm_subnet.proget_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.proget_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "proget_interface_sec_group_association" {
  network_interface_id      = azurerm_network_interface.proget_nic.id
  network_security_group_id = azurerm_network_security_group.proget_nsg.id
}

resource "azurerm_linux_virtual_machine" "proget_vm" {
  name                  = "progetvm-${random_id.suffix.id}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.proget_nic.id]
  size                  = var.virtual_machine.size
  admin_username        = var.virtual_machine.user
  tags                  = var.tags
  user_data = base64encode(templatefile("./bootstrap.tftpl", {
    domain_name : azurerm_public_ip.proget_public_ip.fqdn
    email : var.certificate_registration_email
    connection_string : var.proget_db_connection_string
  }))

  admin_ssh_key {
    username   = var.virtual_machine.user
    public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
  }

  os_disk {
    name                 = "proget-vm-disk-${random_id.suffix.id}"
    caching              = "ReadWrite"
    storage_account_type = var.virtual_machine.disk.account_type
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}
