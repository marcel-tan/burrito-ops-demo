terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 3.75.0"
    }
  }

  # TODO(platform): prod still runs from a laptop-local state file. The migration
  # to the shared azurerm backend was scheduled for Q3 and never happened.
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
