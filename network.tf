resource "google_compute_subnetwork" "public_subnet" {
  name          = "${var.yourname}-${var.env}-pub-net"
  ip_cidr_range = var.rs_public_subnet
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "${var.yourname}-${var.env}-pri-net"
  ip_cidr_range = var.rs_private_subnet
  network       = google_compute_network.vpc.id
}

