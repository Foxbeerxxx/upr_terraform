# Загружаем SSH-ключ из домашнего каталога
locals {
  ssh_key = file("~/.ssh/id_ed25519.pub")
}

# Получаем образ Ubuntu
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2004-lts"
}

# Переменная с конфигурацией для каждой ВМ
variable "each_vm" {
  type = list(object({
    vm_name       = string
    cpu           = number
    ram           = number
    disk_volume   = number
    core_fraction = number
    disk_type     = string
  }))

  default = [
    {
      vm_name       = "main"
      cpu           = 2
      ram           = 2
      disk_volume   = 20
      core_fraction = 100
      disk_type     = "network-ssd"
    },
    {
      vm_name       = "replica"
      cpu           = 2
      ram           = 4
      disk_volume   = 20
      core_fraction = 100
      disk_type     = "network-hdd"
    }
  ]
}


# Создание ВМ с использованием for_each
resource "yandex_compute_instance" "db" {
  for_each = { for vm in var.each_vm : vm.vm_name => vm }

  name        = each.value.vm_name
  platform_id = "standard-v3"
  zone        = var.default_zone

  resources {
    cores         = each.value.cpu
    memory        = each.value.ram
      }

  scheduling_policy {
    preemptible = true              # прерываемая ВМ
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = each.value.disk_volume
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${local.ssh_key}"
  }
}
