# Создание 3 одинаковых дисков по 1 ГБ
resource "yandex_compute_disk" "storage_disks" {
  count       = 3
  name        = "disk-${count.index + 1}"
  size        = 1  
  type        = "network-hdd"
  zone        = var.zone
}

# Одиночная ВМ с динамическим подключением всех 3-х дисков
resource "yandex_compute_instance" "storage" {
  name        = "storage"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 100
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-hdd"
    }
  }

  dynamic "secondary_disk" {
    for_each = yandex_compute_disk.storage_disks[*]
    content {
      disk_id = secondary_disk.value.id
      auto_delete = true
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.example.id]
  }

  metadata = {
  ssh-keys = "ubuntu:${var.ssh_key}"
}
}
variable "zone" {
  default = "ru-central1-a"
}

