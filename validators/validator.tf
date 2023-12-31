# Configure the Google Cloud provider
provider "google" {
  credentials = file("../blockchain.json")
  project     = "alisa-dev"
  region      = "asia-southeast1"  # Singapore region for both instances and static IPs
}

# Define a map to store static IP addresses for each instance
locals {
  instance_names = ["validator01", "validator02", "validator03"]  # Removed "genesis"
  zones          = ["asia-southeast1-a", "asia-southeast1-b", "asia-southeast1-c"]  # Valid zones in "asia-southeast1"
}

# Create a static external IP address for each validator instance in Singapore region
resource "google_compute_address" "validator_static_ips" {
  count  = length(local.instance_names)
  name   = "static-ip-${local.instance_names[count.index]}"
  region = "asia-southeast1"  # Singapore region for static IPs
}

resource "google_compute_instance" "validator" {
  count        = 3  # Adjusted count to 3 instances
  name         = local.instance_names[count.index]
  machine_type = "e2-small"  # Change to the desired machine type
  zone         = local.zones[count.index]  # Use different zones within Singapore region

  boot_disk {
    initialize_params {
      image = "https://www.googleapis.com/compute/v1/projects/alisa-dev/global/images/ubuntu1804tls"
      size  = 30  # Set disk size to 30 GB or as desired
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Use the reserved static IP address for the respective validator
      nat_ip = google_compute_address.validator_static_ips[count.index].address
    }
  }
}

resource "google_compute_firewall" "validator-allow-ports" {
  name    = "validator-allow-ports"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8000", "8080", "8800", "8008", "4004", "5050"]
  }

  source_ranges = ["0.0.0.0/0"]
}
