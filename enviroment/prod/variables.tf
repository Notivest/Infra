variable "location"    { type = string }
variable "environment" { type = string }

variable "services" {
  type = map(object({
    image_tag = string
    cpu       = number
    memory    = string
    env       = map(string)
  }))
}
