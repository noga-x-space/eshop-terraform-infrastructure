variable "tag-name" {
  default = "environment"
}

variable "tag-value" {
  default = "Production"
}


variable "username" {
  type    = string
  default = ""
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = ""
}


variable "port" {
  type    = string
  default = ""
}

variable "db_name" {
  type    = string
  default = ""
}

variable "postgres_version" {
  default = "16"

}

variable "subscription_id" {
  default = ""
}

variable "storage-profile" {
  default = [true]
}


variable "az_web_admin_password" {
  type      = string
  sensitive = true
  default   = "Password1234!"
}

variable "az_db_admin_password" {
  type      = string
  sensitive = true
  default   = "Password1234!"
}

variable "az_back_admin_password" {
  type      = string
  sensitive = true
  default   = "Password1234!"
}
