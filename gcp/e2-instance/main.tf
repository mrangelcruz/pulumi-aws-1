provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}


resource "google_compute_instance" "ubuntu_e2_vm" {
  name         = "my-ubuntu-e2-instance"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-minimal-2204-lts"
    }
  }

  network_interface {
    network = "default" # Use your desired network
    access_config {
      // Ephemeral public IP address
    }
  }

  # Optional: Add SSH keys for access
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}
