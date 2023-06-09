resource "google_compute_network" "vpc" {
  name                    = "${var.yourname}-${var.env}-vpc"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

resource "google_compute_firewall" "allow-internal" {
  name    = "${var.yourname}-${var.env}-fw-allow-internal"
  network = google_compute_network.vpc.name
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  source_ranges = [
    var.rs_private_subnet,
    var.rs_public_subnet
  ]
}

resource "google_compute_firewall" "allow-external" {
  name    = "${var.yourname}-${var.env}-fw-allow-external"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["10000-19999", "8443", "8001", "8070", "8071", "9081", "9443", "8080", "443", "5701-5708", "22"]
    # https://docs.redislabs.com/latest/rs/administering/designing-production/networking/port-configurations/?s=port
    # https://docs.hazelcast.com/hazelcast/5.2/deploy/deploying-on-gcp
  }
  allow {
    protocol = "udp"
    ports    = ["53", "5353", "5701-5708", "54327"]
  }
  source_ranges = ["0.0.0.0/0"]
}
