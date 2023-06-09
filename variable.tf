// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !! PLEASE CHANGE in a terraform.tfvars
// yourname="...."
// credentials="GCP IAM service account key file.json"
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

variable "yourname" {
  # No default
  # Use CLI or interactive input. It is best to setup your own terraform.tfvars
}

// machine name will be "<yourname>-<env>-node1"
// use "default" ie same as default "terraform workspace"
variable "env" {
  default = "default"
}


// ------------------------------------------------------
// Hardware
//
variable "clustersize" {
  # You should use 3 for some more realistic installation
  default = "3"
}

variable "machine_type" {
  #default = "e2-standard-2" // 2 vCPU 8GB
  default = "n2-highcpu-16" // We need a high cpu for testing
  // https://gcpinstances.info/?cost_duration=monthly
  // example with minimal 2vcpu 4GB RAM
  // which leaves about 1.4GB for Redis DB
  // machine_type = "custom-2-4096" // https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
  // other machines of interest:
  //
  // e2-highmem-8   // 8 vCPU 64 GB
  // n2-highcpu-16  // 16 vCPU 32 GB
}

variable "client_machine_type" {
  default = "n2-highcpu-16" // We need a high cpu for memtier
}

// Storage for machines in GB
variable "machine_storage_size" {
  default = 30
}

// Linux image to install
variable "linux_image" {
  default = "ubuntu-minimal-2004-lts"
}

// ------------------------------------------------------
// Redis Enterprise Configuration
//
variable "RS_release" {
  default = "https://s3.amazonaws.com/redis-enterprise-software-downloads/6.4.2/redislabs-6.4.2-61-focal-amd64.tar"
}

variable "RS_admin" {
  default = "admin@redis.io"
}

// -----------------------------------------------------
// -- Hazelcast Configuration
//
variable "HZ_release" {
  default = "5.2.3"
}

// -----------------------------------------------------
// -- jMeter Configuration
//
variable "jmeter_release" {
  default = "https://dlcdn.apache.org/jmeter/binaries/apache-jmeter-5.5.tgz"
}

variable "jmeter_port" {
  default = "1234"
}



// -----------------------------------------------------
// -- DNS Configuration
//
// must be a zone that already exist - we will not create it but will add to it
variable "dns_managed_zone" {
  default = "demo-clusters"
}

// RS DNS and cluster will be
// cluster.<yourname>.demo.redislabs.com
// node1.<yourname>.demo.redislabs.com
// ......<yourname>.demo.redislabs.com
// node3.<yourname>.demo.redislabs.com
variable "dns_zone_dns_name" {
  default = "demo.redislabs.com"
}

// optional edits *************************************
variable "rs_private_subnet" {
  default = "10.26.1.0/24"
}

variable "rs_public_subnet" {
  default = "10.26.2.0/24"
}

// ------------------------------------------------------
// Google Configuration
//
variable "project" {
  default = "central-beach-194106"
}
variable "credentials" {
  default = "central-beach-194106-fda731676157.json"
}
variable "region_name" {
  default = "europe-west1"
}
variable "zone_name" {
  default = "europe-west1-b"
}

variable "google_ssh_key" {
  default = "ssh-google-key.pub"
}

