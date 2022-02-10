
terraform {  
  backend "azurerm" {}
  required_providers {
      azurerm = ">=2.74.0"  
  }
} 
locals{
  common_tags = {
    Environment = var.env_acronym
  }
}
################################## Resource Group  #######################################################

module "module_resource_group" {
  source              = "./modules/resourcegroup"
  rg_name             = "rg-${var.subscription_acronym}app-${var.env_acronym}-${var.location}"
  rg_location         = var.rg_location
  rg_tags             = local.common_tags
}

module "module_resource_group_2" {
  source              = "./modules/resourcegroup"
  rg_name             = "rg-${var.subscription_acronym}core-${var.env_acronym}-${var.location}"
  rg_location         = var.rg_location
  rg_tags             = local.common_tags
}

################################## VNET #######################################################

module "module_virtualnetwork"{
    source            = "./modules/vnet"
    vnet_name         = "vnet-${var.subscription_acronym}-${var.env_acronym}-${var.location}"
    address_space     = var.address_space
    rg_name           = module.module_resource_group_2.rg_name
    rg_location       = module.module_resource_group_2.rg_location
    vnet_tags           = {
           
           Environment = var.env_acronym
           App_Layer = var.App_Layer_NA
    }
}
################################## VNET Diagonostic Settings ###################################
module "module_vnet_diagsettings"{
    source                         = "./modules/vnet_diagsettings"
    vnet_diag_name                 = "diags-vnet-${var.subscription_acronym}-${var.env_acronym}-${var.location}"
    target_resource_id             = module.module_virtualnetwork.vnet_id
    log_analytics_workspace_id     = module.module_loganalytics_workspace.log_analytics_id
    disable_log                   = var.disable_log
}
################################## Subnet #######################################################
module "module_subnet"{
    source            = "./modules/subnet"
    subnet_name       = "snet-${var.subscription_acronym}-${var.env_acronym}-${var.location}"
    vnet_name         = module.module_virtualnetwork.vnet_name
    address_prefix    = var.address_prefix
    rg_name           = module.module_resource_group_2.rg_name
    rg_location       = module.module_resource_group_2.rg_location 
    depends_on        = [module.module_virtualnetwork]
}

module "module_deligatedsubnet1" {
    source                      = "./modules/delegated_subnet"
    subnet_name                 = "dsnet-${var.subscription_acronym}${var.fe_acronym}-${var.env_acronym}-${var.location}-001"
    vnet_name                   = module.module_virtualnetwork.vnet_name
    address_prefix              = var.dsaddress_prefix
    rg_name                     = module.module_resource_group_2.rg_name
    service_delegation          = var.service_delegation
    service_endpoints           = var.service_endpoints
    delegation_name             = var.delegation_name 
    depends_on                  = [module.module_virtualnetwork]     
}

module "module_deligatedsubnet2" {
    source                      = "./modules/delegated_subnet"
    subnet_name                 = "dsnet-${var.subscription_acronym}${var.be_acronym}-${var.env_acronym}-${var.location}-002"
    vnet_name                   = module.module_virtualnetwork.vnet_name
    address_prefix              = var.dsaddress_prefix2
    rg_name                     = module.module_resource_group_2.rg_name
    service_delegation          = var.service_delegation
    service_endpoints           = var.service_endpoints2
    delegation_name             = var.delegation_name
    depends_on                  = [module.module_virtualnetwork]      
}

################################## Storage Account #######################################################
module "module_storage_account_creation" {
  source                      = "./modules/storage_account"
  storage_account_name        = "sa${var.subscription_acronym}${var.env_acronym}${var.location}" 
  rg_name                     =  module.module_resource_group_2.rg_name
  storage_location            =  var.storage_location
  storage_account_type        =  var.storage_account_type
  storage_account_kind        =  var.storage_account_kind
  storage_account_access_tier =  var.storage_account_access_tier
  storage_account_tags = {
          Environment = var.env_acronym
           App_Layer = var.App_Layer_BE
  }
  secure_transfer                     =  var.secure_transfer 
  enable_blob_public_access           =  var.enable_blob_public_access
  storage_account_key_access          =  var.storage_account_key_access
  tls_version                         =  var.tls_version
  enable_hierarchical_namespace       =  var.enable_hierarchical_namespace
  enable_network_file_system_v3       =  var.enable_network_file_system_v3
  large_file_share_enabled            =  var.large_file_share_enabled
  virtual_network_subnet_ids          =  [module.module_deligatedsubnet2.Dsubnet_ID]
  default_action                      =  var.default_action
  enable_publish_microsoft_endpoints  =  var.enable_publish_microsoft_endpoints
  retention_days                      =  var.retention_days
  versioning_enabled                  =  var.versioning_enabled
  change_feed_enabled                 =  var.change_feed_enabled
}

################################## Storage Account Diagnostic Settings ################################################

module "module_storage_account_diagsettings"{
    source                         = "./modules/storage_account_diag_settings"
    storage_diag_name              = "diags-sa-${var.subscription_acronym}-${var.env_acronym}-${var.location}"
    target_resource_id             = module.module_storage_account_creation.storage_account_id
    log_analytics_workspace_id     = module.module_loganalytics_workspace.log_analytics_id
    enable_log                     = var.enable_log

}

################################## Storage Account/Blob Diagnostic Settings ################################################

module "module_storage_account_blob_diagsettings"{
    source                         = "./modules/storage_account_blob_diag_settings"
    storage_diag_name              = "diags-blob-${var.subscription_acronym}-${var.env_acronym}-${var.location}"
    target_resource_id             = "${module.module_storage_account_creation.storage_account_id}/blobServices/default"
    log_analytics_workspace_id     = module.module_loganalytics_workspace.log_analytics_id
    enable_log                     = var.enable_log
}

################################## Log Analytics Workspace ################################################

module "module_loganalytics_workspace"{
    source                       = "./modules/log_analytics_workspace"
    log_analytics_workspace_name = "law-${var.subscription_acronym}-${var.env_acronym}-${var.location}"
    rg_location                  = module.module_resource_group_2.rg_location
    rg_name                      = module.module_resource_group_2.rg_name
    sku                          = var.log_analytics_sku
    retention_in_days            = var.log_analytics_retention
    log_analytics_tags           ={
        
        Environment = var.env_acronym
        App_Layer = var.App_Layer_NA
    }
}
################################ Log Analytics Diagonostic settings #############################
module "module_log_analytics_diagsettings"{
    source                         = "./modules/log_analy_diagsettings"
    log_analytics_diag_name        = "diags-law-${var.subscription_acronym}-${var.env_acronym}-${var.location}"
    target_resource_id             = module.module_loganalytics_workspace.log_analytics_id
    log_analytics_workspace_id     = module.module_loganalytics_workspace.log_analytics_id
    enable_log                    = var.enable_log
}
################################## Key Vault ################################################

module "module_keyvault"{

    source                          = "./modules/key_vault"
    rg_name                         = module.module_resource_group_2.rg_name
    rg_location                     = module.module_resource_group_2.rg_location
    keyvault_name                   = "kv-${var.subscription_acronym}-${var.env_acronym}-${var.location}-1"
    sku_name                        = var.sku_name
    enabled_for_disk_encryption     = var.enabled_for_disk_encryption
    enabled_for_template_deployment = var.enabled_for_template_deployment
    enabled_for_deployment          = var.enabled_for_deployment
    purge_protection_enabled        = var.purge_protection_enabled
    soft_delete_enabled             = var.soft_delete_enabled
    soft_delete_retention_days      = var.soft_delete_retention_days
    key_vault_tags                  = {

        Environment = var.env_acronym
        App_Layer   = var.App_Layer_NA

    }

}
################################## Key Vault Diagnostic Settings ################################################

module "module_keyvault_diagsettings"{
    source                         = "./modules/keyvault_diagsettings"
    kv_diag_name                   = "diags-kv-${var.subscription_acronym}-${var.env_acronym}-${var.location}"
    target_resource_id             = module.module_keyvault.keyvault_id
    log_analytics_workspace_id     = module.module_loganalytics_workspace.log_analytics_id
    enable_log                     = var.enable_log

}

################################## Cosmos DB ################################################
module "module_cosmosdb"{
    source                       = "./modules/cosmos_db"
    cosmos_db_account_name              = "cdb-${var.subscription_acronym}-${var.env_acronym}-${var.location}"
    rg_name                             = module.module_resource_group.rg_name
    rg_location                         = module.module_resource_group.rg_location
    offer_type                          = var.offer_type
    cosmos_kind                         = var.cosmos_kind
    mongo_version                       = var.mongo_version
    consistency_level                   = var.consistency_level
    backup_location                     = var.backup_location
    backup_type                         = var.backup_type
    interval_minutes                    = var.interval_minutes 
    interval_hours                      = var.interval_hours
    subnet_id                           = module.module_deligatedsubnet2.Dsubnet_ID
    container_name                      = var.container_name
    throughput                          = var.throughput
    is_virtual_network_filter_enabled   = var.is_virtual_network_filter_enabled
    enable_automatic_failover           = var.enable_automatic_failover
    enable_free_tier                    = var.enable_free_tier
    access_key_metadata_writes_enabled  = var.access_key_metadata_writes_enabled
    cosmosdb_tags                  = {

        Environment = var.env_acronym
        App_Layer   = var.App_Layer_BE

    }
      
}
#################################### CosmosDB Diagonostic settings ##################################
module "module_cosmosdb_diagsettings"{
    source                         = "./modules/cosmosdb_diagsettings"
    cosmosdb_diag_name             = "diags-cdb-${var.subscription_acronym}-${var.env_acronym}-${var.location}"
    target_resource_id             = module.module_cosmosdb.cosmosdb_id
    log_analytics_workspace_id     = module.module_loganalytics_workspace.log_analytics_id
    enable_log                    = var.enable_log
    disable_log                   = var.disable_log
}
##################################### API Management ####################################
module "module_apimanagement"{
      source                            = "./modules/api_management"
      apim_name                         = "apim-${var.subscription_acronym}-${var.env_acronym}-${var.location}"
      rg_name                           = module.module_resource_group.rg_name
      rg_location                       = module.module_resource_group.rg_location
      publisher_name                    = var.publisher_name
      publisher_email                   = var.publisher_email 
      sku_name                          = var.sku_name_api 
      virtual_network_type              = var.virtual_network_type      
      subnet_id                         = module.module_subnet.subnet_id
      enable_http2                      = var.enable_http2
      enable_backend_ssl30              = var.enable_backend_ssl30
      enable_backend_tls10              = var.enable_backend_tls10
      enable_backend_tls11              = var.enable_backend_tls11
      enable_frontend_ssl30             = var.enable_frontend_ssl30
      enable_frontend_tls10             = var.enable_frontend_tls10
      enable_frontend_tls11             = var.enable_frontend_tls11
      enable_triple_des_ciphers         = var.enable_triple_des_ciphers
      apimanagement_log                 = var.apimanagement_log
      azurerm_application_insights_id   = module.module_app_insights.app_insights_id
      appinsights_instrumentation_key   = module.module_app_insights.instrumentation_key  
      identity_type                     = var.identity_type
      apimanagement_tags           = {

         Environment = var.env_acronym
         App_Layer   = var.App_Layer_NA
     } 
 }


####################################API Management Diagnostic Settings###########################
module "module_api_management_diagsettings"{
    source                         = "./modules/api_management_diagsettings"
    apim_diag_name                = "diags-apim-${var.subscription_acronym}-${var.env_acronym}-${var.location}"
    target_resource_id             = module.module_apimanagement.api_management_id
    log_analytics_workspace_id     = module.module_loganalytics_workspace.log_analytics_id
    enable_log                     = var.enable_log
}
##################################  App Insights ########################################

module "module_app_insights"{
    source                      = "./modules/app_insights"
    app_insights_name           = "appin-${var.subscription_acronym}-${var.env_acronym}-${var.location}"
    rg_name                     = module.module_resource_group.rg_name
    rg_location                 = module.module_resource_group.rg_location
    log_analytics_workspace_id  = module.module_loganalytics_workspace.log_analytics_id
    application_type            = var.application_type
    app_insights_tags       = {
        Environment = var.env_acronym
        App_Layer = var.App_Layer_NA
    }
}
################################ App Insights Diagonostic Settings ############################
module "module_app_insights_diagsettings"{
    source                         = "./modules/appin_diag_settings"
    appinsights_diag_name          = "diags-appin-${var.subscription_acronym}-${var.env_acronym}-${var.location}"
    target_resource_id             = module.module_app_insights.app_insights_id
    log_analytics_workspace_id     = module.module_loganalytics_workspace.log_analytics_id
    enable_log                 = var.enable_log

}
##################################  App Service Plan ########################################
module "module_appserviceplan" {
  source              = "./modules/app_service_plan"
  app_service_plan_name  = "asp-${var.subscription_acronym}${var.fe_acronym}-${var.env_acronym}-${var.location}-001"
  rg_name                = module.module_resource_group.rg_name
  rg_location            = module.module_resource_group.rg_location
  app_service_plan_os    = var.app_service_plan_os
  app_service_tier       = var.app_service_tier
  app_service_size       = var.app_service_size  
    app_service_plan_tags  = {

            Environment = var.env_acronym
            App_Layer   = var.App_Layer_FE
    }

}

module "module_appserviceplan2" {
  source              = "./modules/app_service_plan"
  app_service_plan_name  = "asp-${var.subscription_acronym}${var.be_acronym}-${var.env_acronym}-${var.location}-002"
  rg_name                = module.module_resource_group.rg_name
  rg_location            = module.module_resource_group.rg_location
  app_service_plan_os    = var.app_service_plan_os
  app_service_tier       = var.app_service_tier
  app_service_size       = var.app_service_size  
    app_service_plan_tags  = {

            Environment = var.env_acronym
            App_Layer   = var.App_Layer_BE
    }

}
########################### AppService plan Diagonostic settings#######################################
module "module_appserviceplan01_diagsettings"{
    source                         = "./modules/app_service_plan_diagsettings"
    app_service_plan_diag_name     = "diags-asp-${var.subscription_acronym}-${var.env_acronym}-${var.location}-001"
    target_resource_id             = module.module_appserviceplan.app_service_plan_id
    log_analytics_workspace_id     = module.module_loganalytics_workspace.log_analytics_id
    /* enable_metric_retention_policy = "true"
    metric_retention_days          = "7" */

}
module "module_appserviceplan02_diagsettings"{
    source                         = "./modules/app_service_plan_diagsettings"
    app_service_plan_diag_name     = "diags-asp-${var.subscription_acronym}-${var.env_acronym}-${var.location}-002"
    target_resource_id             = module.module_appserviceplan2.app_service_plan_id
    log_analytics_workspace_id     = module.module_loganalytics_workspace.log_analytics_id
    /* enable_metric_retention_policy = "true"
    metric_retention_days          = "7" */

}

############################ App Service ################################################
module "module_appservice"{
    source                       = "./modules/app_service"
    app_service_name             = "apps-${var.subscription_acronym}${var.fe_acronym}-${var.env_acronym}-${var.location}-001"
    rg_name                      = module.module_resource_group.rg_name
    rg_location                  = module.module_resource_group.rg_location
    app_service_plan_id          = module.module_appserviceplan.app_service_plan_id
    runtime_stack                           = var.runtime_stack
    APPINSIGHTS_INSTRUMENTATIONKEY          = module.module_app_insights.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING   = module.module_app_insights.connection_string
    https_only                              = var.https_only
    ftps_state                              = var.ftps_state
    use_32_bit_worker_process               = var.use_32_bit_worker_process
    identity                                = var.identity
    http2_enabled                           = var.http2_enabled
    subnet_id                               = module.module_deligatedsubnet1.Dsubnet_ID
    virtual_network_subnet_id               = null
    ip_address                              = var.ip_address
    apparname                               = var.apparname
    priority                                = var.priority
    action                                  = var.action
    app_service_tags                = {
        Environment = var.env_acronym
        App_Layer   = var.App_Layer_FE
    } 
}

module "module_appservice2"{
    source                       = "./modules/app_service"
    app_service_name             = "apps-${var.subscription_acronym}${var.be_acronym}-${var.env_acronym}-${var.location}-002"
    rg_name                      = module.module_resource_group.rg_name
    rg_location                  = module.module_resource_group.rg_location
    app_service_plan_id          = module.module_appserviceplan2.app_service_plan_id
    runtime_stack                           = var.runtime_stack2
    APPINSIGHTS_INSTRUMENTATIONKEY          = module.module_app_insights.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING   = module.module_app_insights.connection_string
    https_only                              = var.https_only
    ftps_state                              = var.ftps_state
    use_32_bit_worker_process               = var.use_32_bit_worker_process
    identity                                = var.identity
    http2_enabled                           = var.http2_enabled
    subnet_id                               = module.module_deligatedsubnet2.Dsubnet_ID
    virtual_network_subnet_id               = module.module_deligatedsubnet2.Dsubnet_ID
    ip_address                              = var.ip_address2
    apparname                               = var.apparname2
    priority                                = var.priority2
    action                                  = var.action2   
    app_service_tags                = {

        Environment = var.env_acronym
        App_Layer   = var.App_Layer_BE
    } 
}
########################### App Service Diagonostic Settings ####################################
module "module_appservice01_diagsettings"{
    source                         = "./modules/app_service_diagsettings"
    app_service_diag_name          = "diags-apps-${var.subscription_acronym}-${var.env_acronym}-${var.location}-001"
    target_resource_id             = module.module_appservice.app_service_id
    log_analytics_workspace_id     = module.module_loganalytics_workspace.log_analytics_id
    enable_log                    = var.enable_log

}
module "module_appservice02_diagsettings"{
    source                         = "./modules/app_service_diagsettings"
    app_service_diag_name          = "diags-apps-${var.subscription_acronym}-${var.env_acronym}-${var.location}-002"
    target_resource_id             = module.module_appservice2.app_service_id
    log_analytics_workspace_id     = module.module_loganalytics_workspace.log_analytics_id
    enable_log                    = var.enable_log

}

########################### RBAC role assignments ####################################
/* module "module_adgroup_data_rgapp"{
    
    for_each = toset( [var.group1, var.group2, var.group3] )
    source = "./modules/data_role_assignments"
    display_name = format("%s", each.key)

}

module "module_adgroup_data_rgcore"{
    
    source = "./modules/data_role_assignments"
    display_name = var.group3
}

 module "module_rbac_cosmosdb" {

     source = "./modules/role_assignment"
     resource_id   = module.module_cosmosdb.cosmosdb_id
     role          = var.cosmosdb_role
     principal_id  = module.module_appservice2.appservice_identity
   
 }

 module "module_rbac_apim" {
     source = "./modules/role_assignment"
     resource_id   = module.module_apimanagement.api_management_id
     role          = var.apim_role
     principal_id  = module.module_appservice.appservice_identity
     
 }

 module "module_rbac_appservice1" {

     source = "./modules/role_assignment"
     resource_id   = module.module_appservice.app_service_id
     role          = var.appservice1_role
     principal_id  = module.module_apimanagement.apim_identity
  
 }

module "module_rbac_appservice2" {
 
     source = "./modules/role_assignment"
     resource_id   = module.module_appservice2.app_service_id
     role          = var.appservice2_role
     principal_id  = module.module_apimanagement.apim_identity

}

module "module_rbac_rgapp" {
    for_each  = { (var.group1) = var.role1
                 (var.group2) =  var.role1
                 (var.group3) = var.role2  }
    source = "./modules/role_assignment"
    resource_id   = module.module_resource_group.rg_id
    role          = each.value
    principal_id  = module.module_adgroup_data_rgapp[each.key].adgroup_id
    
}

module "module_rbac_rgcore" {
    
    source = "./modules/role_assignment"
    resource_id   = module.module_resource_group_2.rg_id
    role          = var.role2
    principal_id  = module.module_adgroup_data_rgcore.adgroup_id
    
} */


module "module_data_spdata"  {
    source          = "./modules/data_role_assignments"
    display_name    = var.display_name
}

module "module_rbac_keyvault_ui" {
     source = "./modules/role_assignment"
     resource_id   = module.module_keyvault.keyvault_id
     role          = var.keyvault_role
     principal_id  = module.module_appservice.appservice_identity
}

 module "module_rbac_keyvault_api" {
     source = "./modules/role_assignment"
     resource_id   = module.module_keyvault.keyvault_id
     role          = var.keyvault_role
     principal_id  = module.module_appservice2.appservice_identity
}

 module "module_keyvault_access_policy_devops" {

     source                 = "./modules/key_vault_accesspolicy"
     key_vault_id           = module.module_keyvault.keyvault_id
     tenant_id              = module.module_keyvault.tenant_id
     object_id              = module.module_data_spdata.spobject_id
     key_permissions        = var.key_permissions
     secret_permissions     = var.secret_permissions
     certificate_permissions= var.certificate_permissions
}

module "module_keyvault_access_policy_appservice_ui" {
    source                 = "./modules/key_vault_accesspolicy"
    key_vault_id           = module.module_keyvault.keyvault_id
    tenant_id              = module.module_keyvault.tenant_id
    object_id              = module.module_appservice.appservice_identity
    key_permissions        = var.key_permissions
    secret_permissions     = var.secret_permissions
    certificate_permissions= var.certificate_permissions
    
}

module "module_keyvault_access_policy_appservice_api" {
    source                 = "./modules/key_vault_accesspolicy"
    key_vault_id           = module.module_keyvault.keyvault_id
    tenant_id              = module.module_keyvault.tenant_id
    object_id              = module.module_appservice2.appservice_identity
    key_permissions        = var.key_permissions
    secret_permissions     = var.secret_permissions
    certificate_permissions= var.certificate_permissions    
} 
