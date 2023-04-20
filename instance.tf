resource "google_compute_instance" "node1" {
  name         = "${var.yourname}-${var.env}-1"
  machine_type = var.machine_type
  tags         = ["ssh", "http"]
  boot_disk {
    initialize_params {
      image = var.linux_image
      size  = 30 //GB
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
  tags         = ["ssh", "http"]
  boot_disk {
    initialize_params {
      image = var.linux_image
      size  = 30 // GB
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
  tags         = ["ssh", "http"]
  boot_disk {
    initialize_params {
      image = var.linux_image
      size  = 30 //GB
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
  // Copy hazelcast configuration for google gcp
  provisioner "file" {
    source      = "misc/hazelcast.xml"
    destination = "/opt/hazelcast/config/hazelcast.xml"

    connection {
      host        = self.network_interface.0.access_config.0.nat_ip
      type        = "ssh"
      user        = "root"
      private_key = "$file($pathexpand(var.google_ssh_key))"
      agent       = false
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -H -u hazelcast bash -c \"/opt/hazelcast/bin/hz start >& /tmp/hz.log &\"",
      "sudo -H -u hazelcast bash -c \"/opt/hazelcast/bin/management-center/bin/hz-mc start >& /tmp/hz-mc.log &\""
    ]

    connection {
      host        = self.network_interface.0.access_config.0.nat_ip
      type        = "ssh"
      user        = "root"
      private_key = "$file($pathexpand(var.google_ssh_key))"
      agent       = false
    }
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
  tags         = ["ssh", "http"]
  boot_disk {
    initialize_params {
      image = var.linux_image
      size  = 30 // GB
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

  // Copy hazelcast configuration for google gcp
  provisioner "file" {
    source      = "misc/hazelcast.xml"
    destination = "/opt/hazelcast/config/hazelcast.xml"

    connection {
      host        = self.network_interface.0.access_config.0.nat_ip
      type        = "ssh"
      user        = "root"
      private_key = "$pathexpand('~/.ssh/google_compute_engine.pub')"
      agent       = false
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -H -u hazelcast bash -c \"/opt/hazelcast/bin/hz start >& /tmp/hz.log &\""
    ]

    connection {
      host        = self.network_interface.0.access_config.0.nat_ip
      type        = "ssh"
      user        = "root"
      private_key = "$file($pathexpand(var.google_ssh_key))"
      agent       = false
    }
  }
}

// TODO: Install spring boot app
resource "google_compute_instance" "app" {
  count = var.app_enabled ? 1 : 0

  name         = "${var.yourname}-${var.env}-app"
  machine_type = var.app_machine_type
  tags         = ["ssh", "http"]
  boot_disk {
    initialize_params {
      image = var.linux_image
      size  = 30 //GB
    }
  }
  labels = {
    owner         = var.yourname
    skip_deletion = "yes"
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.google_ssh_key)}"
    startup-script = templatefile("${path.module}/scripts/app.sh", {
      cluster_dns = "cluster.${var.yourname}-${var.env}.${var.dns_zone_dns_name}",
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

// TODO: Install jmeter
resource "google_compute_instance" "jmeter" {
  count = var.app_enabled ? 1 : 0

  name         = "${var.yourname}-${var.env}-jmeter"
  machine_type = var.app_machine_type
  tags         = ["ssh", "http"]
  boot_disk {
    initialize_params {
      image = var.linux_image
      size  = 30 //GB
    }
  }
  labels = {
    owner         = var.yourname
    skip_deletion = "yes"
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.google_ssh_key)}"
    startup-script = templatefile("${path.module}/scripts/jmeter.sh", {
      app_hostname    = "app.${var.yourname}-${var.env}.${var.dns_zone_dns_name}",
      jmeter_hostname = "jmeter.${var.yourname}-${var.env}.${var.dns_zone_dns_name}",
      jmeter_release  = var.jmeter_release
      jmeter_port     = var.jmeter_port
    })
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {
      // Ephemeral IP
    }
  }
}


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


resource "google_dns_record_set" "app" {
  name         = "app.${var.yourname}-${var.env}.${var.dns_zone_dns_name}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_managed_zone

  rrdatas = [google_compute_instance.app.0.network_interface.0.access_config.0.nat_ip]
}

resource "google_dns_record_set" "jmeter" {
  name         = "jmeter.${var.yourname}-${var.env}.${var.dns_zone_dns_name}."
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_managed_zone

  rrdatas = [google_compute_instance.jmeter.0.network_interface.0.access_config.0.nat_ip]
}

resource "google_dns_record_set" "name_servers" {
  name         = "cluster.${var.yourname}-${var.env}.${var.dns_zone_dns_name}."
  type         = "NS"
  ttl          = 60
  managed_zone = var.dns_managed_zone

  rrdatas = flatten([local.n1, flatten(local.nX)])
}

locals {
  n1 = google_dns_record_set.node1.name
  nX = [for xx in google_dns_record_set.nodeX : xx.name]
}

resource "random_password" "password" {
  length           = 12
  special          = true
  override_special = "_"
}

