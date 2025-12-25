variable "datasource_uid" {
  type    = string
  default = "cloudwatch"
}

variable "region" {
  type    = string
  default = ""
}

variable "period" {
  type    = string
  default = ""
}

variable "db_identifiers" {
  type        = list(string)
  description = "List of DBInstanceIdentifier for RDS instances"
}

variable "coordinates" {
  description = "Grid position for the panel"
  type = object({
    x      = number
    y      = number
    width  = number
    height = number
  })
}
