 terraform {
  required_version = ">= 0.11" 
 backend "azurerm" {
  storage_account_name = "__terraformstorageaccount__"
    container_name       = "terraform"
    key                  = "terraform.tfstate"
	access_key  ="__storagekey__"
	}
	}
  

#AKS creation
 
resource "azurerm_resource_group" "rg" {
  name     = "__resource_group_name__"
  location = "__location__"
}

data "azurerm_container_registry" "anilacr" {
  name                = "anilkoranga"
  resource_group_name = "testACR"
}


resource "azurerm_kubernetes_cluster" "aks" {
  name                = "__cluster_name__"
  location            = "__location__"
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "__cluster_name__"
  node_resource_group = "__node_resource_group__"

  default_node_pool {
    name                = "system"
    node_count          = "__system_node_count__"
    vm_size             = "Standard_DS2_v2"
    type                = "VirtualMachineScaleSets"
   # availability_zones  = [1, 2, 3]
    enable_auto_scaling = false
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    load_balancer_sku = "Standard"
    network_plugin    = "kubenet" # CNI
  }
}

resource "azurerm_role_assignment" "role_acrpull" {
  scope                            = data.azurerm_container_registry.anilacr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  skip_service_principal_aad_check = true
}

#App service 

resource "azurerm_resource_group" "dev" {
  name     = "PULTerraform"
  location = "West Europe"
}

resource "azurerm_app_service_plan" "dev" {
  name                = "__appserviceplan__"
  location            = "${azurerm_resource_group.dev.location}"
  resource_group_name = "${azurerm_resource_group.dev.name}"

  sku {
    tier = "Free"
    size = "F1"
  }
}

resource "azurerm_app_service" "dev" {
  name                = "__appservicename__"
  location            = "${azurerm_resource_group.dev.location}"
  resource_group_name = "${azurerm_resource_group.dev.name}"
  app_service_plan_id = "${azurerm_app_service_plan.dev.id}"

}

# App service end here