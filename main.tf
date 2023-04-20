provider "google" {
  project     = var.project
  credentials = var.credentials
  region      = var.region_name
  zone        = var.zone_name
}
######################################################################
output "rs_ui_url" {
  value = "https://cluster.${var.yourname}-${var.env}.${var.dns_zone_dns_name}:8443"
}
output "rs_ui_ip" {
  value = "https://${google_compute_instance.node1.network_interface.0.access_config.0.nat_ip}:8443"
}

output "hz_ui_url" {
  value = "https://hz1.${var.yourname}-${var.env}.${var.dns_zone_dns_name}:8080"
}
output "hz_internal_ips" {
  value = flatten([google_compute_instance.hz1.network_interface.0.network_ip, flatten([google_compute_instance.nodeX.*.network_interface.0.network_ip])])
}


output "rs_cluster_dns" {
  value = "cluster.${var.yourname}-${var.env}.${var.dns_zone_dns_name}"
}
output "rs_nodes_ip" {
  value = flatten([google_compute_instance.node1.network_interface.0.access_config.0.nat_ip, flatten([google_compute_instance.nodeX.*.network_interface.0.access_config.0.nat_ip])])
}
output "rs_nodes_dns" {
  value = flatten(google_dns_record_set.name_servers.rrdatas)
}
output "admin_username" {
  value = var.RS_admin
}
output "admin_password" {
  value = nonsensitive(random_password.password.result)
  #sensitive = true
}
output "how_to_ssh_to_app" {
  value = var.app_enabled ? "gcloud compute ssh ${google_compute_instance.app.0.name}" : ""
}

output "how_to_ssh_to_jmeter" {
  value = var.app_enabled ? "gcloud compute ssh ${google_compute_instance.jmeter.0.name}" : ""
}
output "how_to_ssh_to_rs_node1" {
  value = var.app_enabled ? "gcloud compute ssh ${google_compute_instance.node1.name}" : ""
}
output "how_to_ssh_to_hz_node1" {
  value = var.app_enabled ? "gcloud compute ssh ${google_compute_instance.hz1.name}" : ""
}

output "ssh_google_key" {
  value = var.google_ssh_key
}
