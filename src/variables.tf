###cloud vars
variable "token" {
  type        = string
  description = "y0__xCT0ufIBxjB3RMggtW4jxOA51ZsI3f2sKmFlatvU579i7Vgfw"
}

variable "cloud_id" {
  type        = string
  description = "b1gvjpk4qbrvling8qq1"
}

variable "folder_id" {
  type        = string
  description = "b1gse67sen06i8u6ri78"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "ru-central1-a"
}
variable "default_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "default_cidr"
}

variable "vpc_name" {
  type        = string
  default     = "develop"
  description = "VPC network&subnet name"
}