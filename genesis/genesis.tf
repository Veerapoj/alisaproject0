# Configure the Google Cloud provider
provider "google" {
  credentials = file("../blockchain.json")
  project     = "alisa-dev"
  region      = "asia-southeast1"  # Singapore region for both instances and static IPs
}

# Create a static external IP address for the Genesis instance in Singapore region
resource "google_compute_address" "genesis_static_ip" {
  name   = "static-ip-genesis"
  region = "asia-southeast1"  # Singapore region for static IPs
}

resource "google_compute_instance" "genesis" {
  name         = "genesis"
  machine_type = "e2-small"  # Change to the desired machine type
  zone         = "asia-southeast1-a"  # Specify the desired zone in the Singapore region

  boot_disk {
    initialize_params {
      image = "https://www.googleapis.com/compute/v1/projects/alisa-dev/global/images/ubuntu1804tls"
      size  = 30  # Set disk size to 30 GB or as desired
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Use the reserved static IP address for the Genesis instance
      nat_ip = google_compute_address.genesis_static_ip.address
    }
  }


}

# Create a firewall rule to allow desired ports
resource "google_compute_firewall" "neesis-allow-ports" {
  name    = "genesis-allow-ports"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8000", "8080", "8800", "8008", "4004", "5050"]
  }

  source_ranges = ["0.0.0.0/0"]
}
