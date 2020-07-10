output "ingress_host" {
  description = "The ingress host for the Catalyst Dashboard instance"
  value       = local.ingress_host
  depends_on  = [helm_release.developer-dashboard]
}

output "base_icon_url" {
  description = "The base url that serves icons for the tools"
  value       = "https://${local.icon_host}/tools/icon"
  depends_on  = [helm_release.developer-dashboard]
}
