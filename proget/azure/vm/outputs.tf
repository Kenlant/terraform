output "virtual_machine" {
  value = {
    public_ip   = azurerm_public_ip.proget_public_ip.ip_address
    domain_name = azurerm_public_ip.proget_public_ip.fqdn
    url         = "https://${azurerm_public_ip.proget_public_ip.fqdn}"
    username    = var.virtual_machine.user
  }
}
