variable "rg_name"{
    description = "Resource Group name"
    type        = string
}
variable "rg_location"{
    description = "Location name"
    type        = string
}

variable "apim_name"{
    description = "apim name"
    type        = string
}

variable "publisher_name"{
    description = "publisher name"
    type        = string
}
variable "publisher_email"{
    description = "publisher email"
    type        = string
}

variable "sku_name"{
    description = "SKU Name"
    type        = string
}

variable "virtual_network_type" {
  
}
variable "apimanagement_tags" {
  
}

variable "subnet_id" {
  
}

variable "enable_http2" {
  
}

variable "enable_backend_ssl30" {
  
}

variable "enable_backend_tls10" {
  
}

variable "enable_backend_tls11" {
  
}

variable "enable_frontend_ssl30" {
  
}

variable "enable_frontend_tls10" {
  
}

variable "enable_frontend_tls11" {
  
}

# variable "enable_triple_des_ciphers" {
  
# }

variable "apimanagement_log" {
  
}

variable "azurerm_application_insights_id" {
  
}

variable "appinsights_instrumentation_key" {
  
}

variable "identity_type" {
  
}
