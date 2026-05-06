variable "name_prefix" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "endpoint_public_access" {
  type = bool
}

variable "endpoint_private_access" {
  type = bool
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "node_group" {
  type = object({
    instance_types = list(string)
    min_size       = number
    desired_size   = number
    max_size       = number
    disk_size      = number
  })
}

variable "tags" {
  type = map(string)
}

