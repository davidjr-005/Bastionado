output "attacker_network" {
  value = docker_network.attacker_net.name
}

output "dmz_network" {
  value = docker_network.dmz_net.name
}

output "mgmt_network" {
  value = docker_network.mgmt_net.name
}
