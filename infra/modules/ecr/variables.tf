variable "name_prefix" {
  type = string
}

variable "repositories" {
  type = map(object({
    image_tag_mutability = optional(string, "IMMUTABLE")
    scan_on_push         = optional(bool, true)
  }))
}

variable "tags" {
  type = map(string)
}

