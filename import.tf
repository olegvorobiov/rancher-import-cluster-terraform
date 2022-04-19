resource "rancher2_cluster" "imported-cluster" {
  name = var.cluster_name
  description = "Rancher imported cluster"
}
