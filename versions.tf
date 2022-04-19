terraform {
  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
      version = "1.23.0"
    }
    
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.10.0"
    }
  }
}
