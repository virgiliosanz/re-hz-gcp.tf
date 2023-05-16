resource "google_compute_instance" "node1" {
  name         = "${var.yourname}-${var.env}-1"
  machine_type = var.machine_type
  boot_disk {
    initialize_params {
      image = var.linux_image
      size  = var.machine_storage_size
    }
  }
  labels = {
    owner         = var.yourname
    skip_deletion = "yes"
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.google_ssh_key)}"
    startup-script = templatefile("${path.module}/scripts/re_instance.sh", {
      cluster_dns = "cluster.${var.yourname}-${var.env}.${var.dns_zone_dns_name}",
      node_id     = 1
      node_1_ip   = ""
      RS_release  = var.RS_release
      RS_admin    = var.RS_admin
      RS_password = random_password.password.result
    })
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {
      // Ephemeral IP
    }
  }
}

resource "google_compute_instance" "nodeX" {
  count = var.clustersize - 1

  name         = "${var.yourname}-${var.env}-${count.index + 1 + 1}" #+1+1 as we have node1 above
  machine_type = var.machine_type
  boot_disk {
    initialize_params {
      image = var.linux_image
      size  = var.machine_storage_size
    }
  }
  labels = {
    owner         = var.yourname
    skip_deletion = "yes"
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.google_ssh_key)}"
    startup-script = templatefile("${path.module}/scripts/re_instance.sh", {
      cluster_dns = "cluster.${var.yourname}-${var.env}.${var.dns_zone_dns_name}",
      node_id     = count.index + 1 + 1
      node_1_ip   = google_compute_instance.node1.network_interface.0.network_ip
      RS_release  = var.RS_release
      RS_admin    = var.RS_admin
      RS_password = random_password.password.result
    })
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {
      // Ephemeral IP
    }
  }
}

resource "google_compute_instance" "hz1" {
  name         = "${var.yourname}-${var.env}-hz-1"
  machine_type = var.machine_type
  boot_disk {
    initialize_params {
      image = var.linux_image
      size  = var.machine_storage_size
    }
  }
  labels = {
    owner         = var.yourname
    skip_deletion = "yes"
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.google_ssh_key)}"
    startup-script = templatefile("${path.module}/scripts/hz_instance.sh", {
      node_id    = 1
      node_1_ip  = ""
      HZ_release = var.HZ_release
    })
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {
      // Ephemeral IP
    }
  }
}

resource "google_compute_instance" "hzX" {
  count = var.clustersize - 1

  name         = "${var.yourname}-${var.env}-hz-${count.index + 1 + 1}" #+1+1 as we have node1 above
  machine_type = var.machine_type
  boot_disk {
    initialize_params {
      image = var.linux_image
      size  = var.machine_storage_size
    }
  }
  labels = {
    owner         = var.yourname
    skip_deletion = "yes"
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.google_ssh_key)}"
    startup-script = templatefile("${path.module}/scripts/hz_instance.sh", {
      node_id    = count.index + 1 + 1
      node_1_ip  = google_compute_instance.hz1.network_interface.0.network_ip
      HZ_release = var.HZ_release
    })
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {
      // Ephemeral IP
    }
  }
}

resource "google_compute_instance" "bentier" {
  name         = "${var.yourname}-${var.env}-bentier"
  machine_type = var.client_machine_type
  boot_disk {
    initialize_params {
      image = var.linux_image
      size  = var.machine_storage_size
    }
  }
  labels = {
    owner         = var.yourname
    skip_deletion = "yes"
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.google_ssh_key)}"
    startup-script = templatefile("${path.module}/scripts/bentier.sh", {
      cluster_dns = "cluster.${var.yourname}-${var.env}.${var.dns_zone_dns_name}",
      RS_admin    = var.RS_admin
      RS_password = random_password.password.result
      hz_node_ips = join(" ", [for s in flatten([google_compute_instance.hz1.network_interface.0.network_ip, flatten([google_compute_instance.nodeX.*.network_interface.0.network_ip])]) : format("%q", s)])
    })
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {
      // Ephemeral IP
    }
  }
}

// TODO: Install jmeter
resource "google_compute_instance" "jmeter" {
  name         = "${var.yourname}-${var.env}-jmeter"
  machine_type = var.client_machine_type
  boot_disk {
    initialize_params {
      image = var.linux_image
      size  = var.machine_storage_size
    }
  }
  labels = {
    owner         = var.yourname
    skip_deletion = "yes"
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.google_ssh_key)}"
    startup-script = templatefile("${path.module}/scripts/jmeter.sh", {
      bentier_hostname = "bentier.${var.yourname}-${var.env}.${var.dns_zone_dns_name}",
      jmeter_hostname  = "jmeter.${var.yourname}-${var.env}.${var.dns_zone_dns_name}",
      jmeter_release   = var.jmeter_release
      jmeter_port      = var.jmeter_port
    })
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {
      // Ephemeral IP
    }
  }
}

// ----------------
// DNS Redis enterprise cluster
resource "google_dns_record_set" "node1" {
  name         = "node1.${var.yourname}-${var.env}.${var.dns_zone_dns_name}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_managed_zone

  rrdatas = [google_compute_instance.node1.network_interface.0.access_config.0.nat_ip]
}
resource "google_dns_record_set" "nodeX" {
  count = var.clustersize - 1

  name         = "node${count.index + 1 + 1}.${var.yourname}-${var.env}.${var.dns_zone_dns_name}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_managed_zone

  rrdatas = [google_compute_instance.nodeX[count.index].network_interface.0.access_config.0.nat_ip]
}

locals {
  n1 = google_dns_record_set.node1.name
  nX = [for xx in google_dns_record_set.nodeX : xx.name]
}

resource "google_dns_record_set" "name_servers" {
  name         = "cluster.${var.yourname}-${var.env}.${var.dns_zone_dns_name}."
  type         = "NS"
  ttl          = 60
  managed_zone = var.dns_managed_zone

  rrdatas = flatten([local.n1, flatten(local.nX)])
}

// ----------------
// DNS Hazelcast Cluster
resource "google_dns_record_set" "hz1" {
  name         = "hz1.${var.yourname}-${var.env}.${var.dns_zone_dns_name}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_managed_zone

  rrdatas = [google_compute_instance.hz1.network_interface.0.access_config.0.nat_ip]
}
resource "google_dns_record_set" "hzX" {
  count = var.clustersize - 1

  name         = "hz${count.index + 1 + 1}.${var.yourname}-${var.env}.${var.dns_zone_dns_name}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_managed_zone

  rrdatas = [google_compute_instance.hzX[count.index].network_interface.0.access_config.0.nat_ip]
}

// ----------------
// DNS Entries for the rest of machines
resource "google_dns_record_set" "bentier" {
  name         = "bentier.${var.yourname}-${var.env}.${var.dns_zone_dns_name}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_managed_zone

  rrdatas = [google_compute_instance.bentier.network_interface.0.access_config.0.nat_ip]
}

resource "google_dns_record_set" "jmeter" {
  name         = "jmeter.${var.yourname}-${var.env}.${var.dns_zone_dns_name}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_managed_zone

  rrdatas = [google_compute_instance.jmeter.network_interface.0.access_config.0.nat_ip]
}



resource "random_password" "password" {
  length           = 12
  special          = true
  override_special = "_"
}

