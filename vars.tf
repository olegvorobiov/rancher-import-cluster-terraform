variable "rancher2_access_key" {
    type = string
    default = "token-blabla"
    description = "Will be visible when you create API keys for an admin user"
}

variable "rancher2_secret_key" {
    type = string
    default = "blablablablablablablablablablablablablablablablablabla"
    description = "Will be visible when you create API keys for an admin user"
}

variable "rancher_server_url" {
    type = string
    default = "https://yourdomain.com"
}

variable "rancher_server_ca_checksum" {
    type = string
    default = "blablablablablablablablablablablablablablablablablablablablablabla"
    description = "Can be pulled from a manifest, will stay the same for rancher server"
}

variable "rancher_server_install_uuid" {
    type = string
    default = "blabla-blablablablab-lablablabla"
    description = "Can be pulled from a manifest, will stay the same for rancher server"
}

variable "k8s_config_path" {
    type = string
    default = "/home/olegv/config.yaml"
    description = "A path to a kubeconfig file for a downstream cluster to be added"
}

variable "cluster_name" {
    type = string
    default = "imported-lab-1"
}