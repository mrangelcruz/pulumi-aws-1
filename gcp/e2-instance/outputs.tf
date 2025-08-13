output "instance_external_ip" {
  description = "The external IP address of the VM instance."
  value       = google_compute_instance.ubuntu_e2_vm.network_interface[0].access_config[0].nat_ip
}