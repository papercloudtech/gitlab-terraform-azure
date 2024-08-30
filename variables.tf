variable "ssh_username" {
  type = string
}

variable "ssh_password" {
  type      = string
  sensitive = true
}

variable "gitlab_root_password" {
  type = string
  sensitive = true
  default = "1234"

  validation {
    condition     = length(var.gitlab_root_password) >= 8 && length(regexall("[A-Z]", var.gitlab_root_password)) > 0 && length(regexall("[a-z]", var.gitlab_root_password)) > 0 && length(regexall("[0-9]", var.gitlab_root_password)) > 0 && length(regexall("[^a-zA-Z0-9]", var.gitlab_root_password)) > 0
    error_message = "The root_password must be at least 8 characters long and include at least one uppercase letter, one lowercase letter, one number, and one special character."
  }
}

variable "domain_name" {
  type = string
  sensitive = true
  default = "example.com"
}

variable "ssh_public_key_path" {
  type = string
  default = null
}

variable "resource_location" {
  type    = string
  default = "East US"

  validation {
    condition     = contains(["Australia Central", "Australia East", "Australia Southeast", "Canada Central", "Canada East", "Central India", "East Asia", "East US", "East US 2", "France Central", "Germany West Central", "Israel Central", "Italy North", "North Europe", "Norway East", "Poland Central", "South Africa North", "Sweden Central", "Switzerland North", "UAENorth", "UK South", "West US", "West US 3"], var.resource_location)
    error_message = "The location must be one of the specified Azure regions."
  }
}

variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}

variable "azure_subscription_id" {
  type      = string
  sensitive = true
  default   = null
}

variable "azure_tenant_id" {
  type      = string
  sensitive = true
  default   = null
}

variable "azure_client_id" {
  type      = string
  sensitive = true
  default   = null
}

variable "azure_client_secret" {
  type      = string
  sensitive = true
  default   = null
}
