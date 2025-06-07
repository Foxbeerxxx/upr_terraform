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
5. `Нифраструктура разварачивается в YC`

![3](https://github.com/Foxbeerxxx/upr_terraform/blob/main/img/img3.png)

6. `Для теста пробую зайти на web-1 `

```
ssh ubuntu@51.250.7.239
```
![4](https://github.com/Foxbeerxxx/upr_terraform/blob/main/img/img4.png)

---

### Задание 3

`Приведите ответ в свободной форме........`

1. `Заполните здесь этапы выполнения, если требуется ....`
2. `Заполните здесь этапы выполнения, если требуется ....`
3. `Заполните здесь этапы выполнения, если требуется ....`
4. `Заполните здесь этапы выполнения, если требуется ....`
5. `Заполните здесь этапы выполнения, если требуется ....`
6. 

```
Поле для вставки кода...
....
....
....
....
```

`При необходимости прикрепитe сюда скриншоты
![Название скриншота](ссылка на скриншот)`

### Задание 4

`Приведите ответ в свободной форме........`

1. `Заполните здесь этапы выполнения, если требуется ....`
2. `Заполните здесь этапы выполнения, если требуется ....`
3. `Заполните здесь этапы выполнения, если требуется ....`
4. `Заполните здесь этапы выполнения, если требуется ....`
5. `Заполните здесь этапы выполнения, если требуется ....`
6. 

```
Поле для вставки кода...
....
....
....
....
```

`При необходимости прикрепитe сюда скриншоты
![Название скриншота](ссылка на скриншот)`
