terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 3.75.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-burritoworks-tfstate"
    storage_account_name = "stbwtfstateprod"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
