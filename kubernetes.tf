## Resources to be created by the manifest

## NAMESPACE

resource "kubernetes_namespace" "cattle-system" {
  metadata {
    name = "cattle-system"
  }

  depends_on = [
    rancher2_cluster.imported-cluster
  ]

}

## SERVICE ACCOUNT

resource "kubernetes_service_account" "cattle" {
  metadata {
    name = "cattle"
    namespace = "cattle-system"
  }

  depends_on = [
    kubernetes_namespace.cattle-system,
    rancher2_cluster.imported-cluster
  ]
}

## CLUSTER ROLE

resource "kubernetes_cluster_role" "proxy-clusterrole-kubeapiserver" {
  metadata {
    name = "proxy-clusterrole-kubeapiserver"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes/metrics", "nodes/proxy", "nodes/stats", "nodes/log", "nodes/spec"]
    verbs      = ["get", "list", "watch", "create"]
  }
  
  depends_on = [
    rancher2_cluster.imported-cluster
  ]
}

## CLUSTER ROLE BINDING

resource "kubernetes_cluster_role_binding" "proxy-role-binding-kubernetes-master" {
  metadata {
    name = "proxy-role-binding-kubernetes-master"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "proxy-clusterrole-kubeapiserver"
  }
  subject {
    kind      = "User"
    name      = "kube-apiserver"
    api_group = "rbac.authorization.k8s.io"
  }
  
  depends_on = [
    kubernetes_cluster_role.proxy-clusterrole-kubeapiserver,
    rancher2_cluster.imported-cluster
  ]
}

## CLUSTER ROLE

resource "kubernetes_cluster_role" "cattle-admin" {
  metadata {
    name = "cattle-admin"
    labels = {
      "cattle.io/creator" = "norman"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
  rule {
    non_resource_urls = ["*"]
    verbs = ["*"]
  }

  depends_on = [
    rancher2_cluster.imported-cluster
  ]
}

## CLUSTER ROLE BINDING

resource "kubernetes_cluster_role_binding" "cattle-admin-binding" {
  metadata {
    name = "cattle-admin-binding"
    labels = {
      "cattle.io/creator" = "norman"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cattle-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "cattle"
    namespace = "cattle-system"
  }
  
  depends_on = [
    kubernetes_cluster_role.cattle-admin,
    kubernetes_service_account.cattle,
    rancher2_cluster.imported-cluster
  ]
}

## SERVICE

resource "kubernetes_service" "cattle-cluster-agent" {
  metadata {
    name = "cattle-cluster-agent"
    namespace = "cattle-system"
  }
  spec {
    selector = {
      app = "cattle-cluster-agent"
    }
    port {
      port        = 80
      target_port = 80
      protocol = "TCP"
      name = "http"
    }
    port {
      port        = 443
      target_port = 444
      protocol = "TCP"
      name = "https-internal"
    }
  }
  
  depends_on = [
    kubernetes_namespace.cattle-system,
    rancher2_cluster.imported-cluster
  ]
}

## SECRET

resource "kubernetes_secret" "cattle-credentials" {
  metadata {
    generate_name = "cattle-credentials-"
    namespace = "cattle-system"
  }

  data = {
    url = var.rancher_server_url
    token = "${rancher2_cluster.imported-cluster.cluster_registration_token[0].token}"
  }
  
  depends_on = [
    kubernetes_namespace.cattle-system,
    rancher2_cluster.imported-cluster
  ]
}

## DEPLOYMENT

resource "kubernetes_deployment" "cattle-cluster-agent" {
  metadata {
    name = "cattle-cluster-agent"
    namespace = "cattle-system"
    annotations = {
      "management.cattle.io/scale-available" = "2"
    }
  }

  spec {

    selector {
      match_labels = {
        app = "cattle-cluster-agent"
      }
    }

    template {
      metadata {
        labels = {
          app = "cattle-cluster-agent"
        }
      }

      spec {
        container {
          image = "rancher/rancher-agent:v2.6.3"
          name  = "cluster-register"
          image_pull_policy = "IfNotPresent"
          env {
            name = "CATTLE_IS_RKE"
            value = "false"
          }
          env {
            name = "CATTLE_SERVER"
            value = var.rancher_server_url
          }
          env {
            name = "CATTLE_CA_CHECKSUM"
            value = var.rancher_server_ca_checksum
          }
          env {
            name = "CATTLE_CLUSTER"
            value = "true"
          }
          env {
            name = "CATTLE_K8S_MANAGED"
            value = "true"
          }
          env {
            name = "CATTLE_CLUSTER_REGISTRY"
            value = ""
          }
          env {
            name = "CATTLE_SERVER_VERSION"
            value = "v2.6.3"
          }
          env {
            name = "CATTLE_INSTALL_UUID"
            value = var.rancher_server_install_uuid
          }
          env {
            name = "CATTLE_INGRESS_IP_DOMAIN"
            value = "sslip.io"
          }
          volume_mount {
            name = "cattle-credentials"
            mount_path = "/cattle-credentials"
            read_only = "true"
          }
        }
        volume {
          name = "cattle-credentials"
          secret {
              secret_name = "${kubernetes_secret.cattle-credentials.metadata[0].name}"
              default_mode = "0500"
          }
        }
        toleration {
          effect = "NoSchedule"
          key = "node-role.kubernetes.io/controlplane"
          value = "true"
        }
        toleration {
          effect = "NoSchedule"
          key = "node-role.kubernetes.io/control-plane"
          operator =  "Exists"
        }
        toleration {
          effect = "NoSchedule"
          key = "node-role.kubernetes.io/master"
          operator =  "Exists"
        }
        service_account_name = "cattle"
        affinity {
          pod_affinity {
            preferred_during_scheduling_ignored_during_execution {
                weight = 100
                pod_affinity_term {
                  label_selector {
                      match_expressions {
                          key = "app"
                          operator = "In"
                          values = ["cattle-cluster-agent"]
                      }
                  }
                  topology_key = "kubernetes.io/hostname"
                }
            }
          }
          node_affinity {
            required_during_scheduling_ignored_during_execution {
                node_selector_term {
                  match_expressions {
                      key = "beta.kubernetes.io/os"
                      operator = "NotIn"
                      values = ["windows"]
                  }
                }
            }
            preferred_during_scheduling_ignored_during_execution {
                weight = 100
                preference {
                  match_expressions {
                      key = "node-role.kubernetes.io/controlplane"
                      operator = "In"
                      values = ["true"]
                  }
                }
            }
            preferred_during_scheduling_ignored_during_execution {
                weight = 100
                preference {
                  match_expressions {
                      key = "node-role.kubernetes.io/control-plane"
                      operator = "In"
                      values = ["true"]
                  }
                }
            }
            preferred_during_scheduling_ignored_during_execution {
                weight = 100
                preference {
                  match_expressions {
                      key = "node-role.kubernetes.io/master"
                      operator = "In"
                      values = ["true"]
                  }
                }
            }
            preferred_during_scheduling_ignored_during_execution {
                weight = 1
                preference {
                  match_expressions {
                    key = "node-role.kubernetes.io/cluster-agent"
                    operator = "In"
                    values = ["true"]  
                  }
                }
            }
          }
        }
      }
    }
    strategy {
      type = "RollingUpdate"
      rolling_update {
          max_unavailable = "0"
          max_surge = "1"
      }
    }
  }
  
  depends_on = [
    rancher2_cluster.imported-cluster,
    kubernetes_secret.cattle-credentials
  ]
}