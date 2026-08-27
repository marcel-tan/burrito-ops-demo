terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # TODO(platform): provider is two majors behind, nobody has had time to test the upgrade
      version = "= 3.75.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-burritoworks-tfstate"
    storage_account_name = "stbwtfstatedev"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
