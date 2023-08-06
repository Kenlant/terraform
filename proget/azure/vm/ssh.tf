resource "random_id" "ssh_key_name" {
  byte_length = 8
}

resource "azapi_resource_action" "ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = "proget-vm-key-${random_id.ssh_key_name.id}"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
}

resource "local_file" "private_key" {
  content  = jsondecode(azapi_resource_action.ssh_public_key_gen.output).privateKey
  filename = "private_key.pem"
}
