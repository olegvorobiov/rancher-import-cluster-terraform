provider "rancher2" {
  api_url    = var.rancher_server_url
  access_key = var.rancher2_access_key
  secret_key = var.rancher2_secret_key
  insecure = true
}

provider "kubernetes" {
  config_path    = var.k8s_config_path
}
