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
  icon_host    = "dashboard-icons.${var.cluster_ingress_hostname}"
  endpoint_url = "http${var.tls_secret_name != "" ? "s" : ""}://${local.ingress_host}"
  gitops_dir   = var.gitops_dir != "" ? var.gitops_dir : "${path.cwd}/gitops"
  chart_name   = "dashboard"
  chart_dir    = "${local.gitops_dir}/${local.chart_name}"
  global = {
    ingressSubdomain = var.cluster_ingress_hostname
    clusterType = var.cluster_type
  }
  dashboard_config = {
    sso = {
      enabled = var.enable_sso
    }
    image = {
      tag = var.image_tag
    }
    tlsSecretName = var.tls_secret_name
    iconHost = local.icon_host
  }
  tool_config = {
    name = "dashboard"
    url = local.endpoint_url
    applicationMenu = true
    displayName = "Developer Dashboard"
  }
}

resource "null_resource" "setup-chart" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.chart_dir} && cp -R ${path.module}/chart/${local.chart_name}/* ${local.chart_dir}"
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

resource "local_file" "dashboard-values" {
  depends_on = [null_resource.setup-chart, null_resource.delete-consolelink]

  content  = yamlencode({
    global = local.global
    developer-dashboard = local.dashboard_config
    tool-config = local.tool_config
  })
  filename = "${local.chart_dir}/values.yaml"
}

resource "null_resource" "print-values" {
  provisioner "local-exec" {
    command = "cat ${local_file.dashboard-values.filename}"
  }
}

resource "helm_release" "dashboard" {
  depends_on = [local_file.dashboard-values]
  count = var.mode != "setup" ? 1 : 0

  name         = "dashboard"
  chart        = local.chart_dir
  namespace    = var.releases_namespace
  force_update = true
  replace      = true
}
