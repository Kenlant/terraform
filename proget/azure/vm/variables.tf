variable "resource_group_name" {
  type        = string
  description = "Name of Azure resource group"
}

variable "location" {
  type        = string
  description = "Azure regions"
}

variable "domain_name" {
  type        = string
  description = "DNS label for public IP"
}

variable "certificate_registration_email" {
  type        = string
  description = "Mail address to register ssl certificate account"
}

variable "proget_db_connection_string" {
  type        = string
  description = "Proget database connection string "
}

variable "tags" {
  type        = map(any)
  description = "Common resource tags"
  default = {
    app = "proget"
  }
}

variable "virtual_machine" {
  type = object({
    size = string,
    user = string
    disk = object({
      account_type = string
    })
  })
  default = {
    size = "Standard_B1s"
    user = "azureuser"
    disk = {
      account_type = "Standard_LRS"
    }
  }
}
