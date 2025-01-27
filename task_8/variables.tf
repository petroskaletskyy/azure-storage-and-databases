variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}  

variable "ip" {
  description = "Public IP address to allow access to the SQL Server"
  type        = string
}