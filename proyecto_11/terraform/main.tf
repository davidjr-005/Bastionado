resource "docker_network" "attacker_net" {
  name = "${var.project_name}_attacker_net"
  ipam_config {
    subnet = "10.11.0.0/24"
  }
}

resource "docker_network" "dmz_net" {
  name = "${var.project_name}_dmz_net"
  ipam_config {
    subnet = "10.12.0.0/24"
  }
}

resource "docker_network" "mgmt_net" {
  name = "${var.project_name}_mgmt_net"
  ipam_config {
    subnet = "10.30.0.0/24"
  }
}

# Este Terraform documenta el despliegue Docker exigido por el proyecto.
# La ejecucion recomendada para las pruebas es docker compose, porque simplifica
# privilegios NET_ADMIN, volumenes de logs y comandos interactivos.
