# Домашнее задание к занятию "`Управляющие конструкции в коде Terraform`" - `Татаринцев Алексей`

---

### Задание 1

1. `Заполняю проект своимми значениями и пробую запускать`
```
terraform init
terraform apply
Код запустился 
```
2. `Захожу в вебконсоль YC и проверяю, что есть`

![1](https://github.com/Foxbeerxxx/upr_terraform/blob/main/img/img1.png)

![2](https://github.com/Foxbeerxxx/upr_terraform/blob/main/img/img2.png)

---

### Задание 2

1. `Пишу файл count-vm.tf и забиваю наполнение`

```
resource "yandex_compute_instance" "web" {
  count       = 2
  name        = "web-${count.index + 1}"
  platform_id = "standard-v3"
  zone        = var.default_zone

  resources {
    cores         = 2
    memory        = 2
      }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.example.id]
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    ssh-keys = "ubuntu:${local.ssh_key}"
  }

  depends_on = [
    yandex_compute_instance.db["main"],
    yandex_compute_instance.db["replica"]
  ]
}

```

2. `Пишу наполнение файлаfor_each-vm.tf`

```
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

```

3. `Провожу траблшутинг кода`
4. `Запускаю terraform init и terraform apply `
5. `Ифраструктура разварачивается в YC`

![3](https://github.com/Foxbeerxxx/upr_terraform/blob/main/img/img3.png)

6. `Для теста пробую зайти на web-1 `

```
ssh ubuntu@51.250.7.239
```
![4](https://github.com/Foxbeerxxx/upr_terraform/blob/main/img/img4.png)

---

### Задание 3


1. `Пишу файл disk_vm.tf `

```
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


```


2. `Провожу много разборок ошибок и как итог terraform init и  terraform apply отрабатывают верно`

![5](https://github.com/Foxbeerxxx/upr_terraform/blob/main/img/img5.png)


### Задание 4


1. ` Пишу файл inventory.tmpl`

```
[webservers]
%{ for host in web_hosts ~}
${host.name} ansible_host=${host.ip} fqdn=${host.fqdn}
%{ endfor ~}

[databases]
%{ for host in db_hosts ~}
${host.name} ansible_host=${host.ip} fqdn=${host.fqdn}
%{ endfor ~}

[storage]
%{ for host in storage_hosts ~}
${host.name} ansible_host=${host.ip} fqdn=${host.fqdn}
%{ endfor ~}


```

2. `Пишу файл ansible.tf`

```
resource "local_file" "inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    web_hosts = [
      for vm in yandex_compute_instance.web : {
        name = vm.name
        ip   = vm.network_interface[0].nat_ip_address
        fqdn = vm.fqdn
      }
    ]
    db_hosts = [
      for vm in yandex_compute_instance.db : {
        name = vm.name
        ip   = vm.network_interface[0].nat_ip_address
        fqdn = vm.fqdn
      }
    ]
    storage_hosts = [
      {
        name = yandex_compute_instance.storage.name
        ip   = yandex_compute_instance.storage.network_interface[0].nat_ip_address
        fqdn = yandex_compute_instance.storage.fqdn
      }
    ]
  })

  filename = "${path.module}/inventory"
}


```
3. `После выполнения terraform init и terraform apply создается файл с нужным содержанием`

![6](https://github.com/Foxbeerxxx/upr_terraform/blob/main/img/img6.png)

