provider "helm" {
  version = ">= 1.1.1"

  kubernetes {
    config_path = var.cluster_config_file
  }
}

locals {
  tmp_dir      = "${path.cwd}/.tmp"
  cluster_type = var.cluster_type == "kubernetes" ? "kubernetes" : "openshift"
  ingress_host = "dashboard-${var.releases_namespace}.${var.cluster_ingress_hostname}"
  endpoint_url = "http${var.tls_secret_name != "" ? "s" : ""}://${local.ingress_host}"
}

resource "helm_release" "developer-dashboard" {
  name         = "developer-dashboard"
  repository   = "https://ibm-garage-cloud.github.io/toolkit-charts/"
  chart        = "developer-dashboard"
  version      = var.chart_version
  namespace    = var.releases_namespace
  force_update = true
  replace      = true

  set {
    name  = "clusterType"
    value = local.cluster_type
  }

  set {
    name  = "ingressSubdomain"
    value = var.cluster_ingress_hostname
  }

  set {
    name  = "sso.enabled"
    value = var.enable_sso
  }

  set {
    name  = "tlsSecretName"
    value = var.tls_secret_name
  }
}

resource "null_resource" "delete-consolelink" {
  count = var.cluster_type != "kubernetes" ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl delete consolelink -l grouping=garage-cloud-native-toolkit -l app=dashboard || exit 0"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "helm_release" "dashboard-config" {
  depends_on = [helm_release.developer-dashboard, null_resource.delete-consolelink]

  name         = "dashboard"
  repository   = "https://ibm-garage-cloud.github.io/toolkit-charts/"
  chart        = "tool-config"
  namespace    = var.releases_namespace
  force_update = true
  replace      = true

  set {
    name  = "url"
    value = local.endpoint_url
  }

  set {
    name  = "applicationMenu"
    value = var.cluster_type != "kubernetes"
  }

  set {
    name  = "ingressSubdomain"
    value = var.cluster_ingress_hostname
  }

  set {
    name  = "displayName"
    value = "Developer Dashboard"
  }
}
