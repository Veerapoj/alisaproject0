# Configure the Google Cloud provider
provider "google" {
  credentials = file("gcp-auth.json")
  project     = "alisa-dev"
  region      = "asia-southeast1"  # Singapore region for both instances and static IPs
}

# Define a map to store static IP addresses for each instance
locals {
  instance_names = ["genesis", "validator01", "validator02", "validator03"]
  zones          = ["asia-southeast1-a", "asia-southeast1-b", "asia-southeast1-c"]  # Valid zones in "asia-southeast1"
}

# Create a static external IP address for each validator instance in Singapore region
resource "google_compute_address" "validator_static_ips" {
  count  = length(local.instance_names)
  name   = "static-ip-${local.instance_names[count.index]}"
  region = "asia-southeast1"  # Singapore region for static IPs
}

resource "google_compute_instance" "validator" {
  count        = 4
  name         = local.instance_names[count.index]
  machine_type = "e2-small"  # Change to the desired machine type
  zone         = local.instance_names[count.index] == "genesis" ? local.zones[0] : local.zones[count.index - 1]  # Use different zones within Singapore region

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

 # Use a null_resource to execute Ansible playbook remotely
# metadata_startup_script = <<-EOT
#   #!/bin/bash
#   apt-get update
#   apt-get install -y ansible
#   curl -L https://bootstrap.pypa.io/get-pip.py | python3
#   pip install sawtooth-sdk
#
#   INSTANCE_NAME=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)
#   SSH_USER=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/ssh-user)
#   echo "$SSH_USER" > ansible_inventory_ssh_user.txt
#   echo '$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/selfLink | cut -d/ -f6)' > ansible_inventory.txt
#   ansible-playbook -i '$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/selfLink | cut -d/ -f6),' -u "$SSH_USER" -e 'ansible_python_interpreter=/usr/bin/python3' sawtooth-ansible-cof.yaml
#   EOT

}

resource "google_compute_firewall" "my-allow-ports" {
  name    = "my-allow-ports"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8000", "8080", "8800", "8008", "4004", "5050"]
  }

  source_ranges = ["0.0.0.0/0"]
}
