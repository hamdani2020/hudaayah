variable "name" {
  description = "Name prefix for security resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC the security group belongs to."
  type        = string
}

variable "ssh_ingress_cidrs" {
  description = "CIDRs allowed to SSH (port 22). Keep this tight; empty disables SSH ingress. Prefer SSM Session Manager over opening SSH."
  type        = list(string)
  default     = []
}

variable "http_ingress_cidrs" {
  description = "CIDRs allowed to reach HTTP (80)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_ingress_cidrs" {
  description = "CIDRs allowed to reach HTTPS (443)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_ingress_cidrs" {
  description = "CIDRs allowed to reach the Django app port (8000)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags applied to the security group."
  type        = map(string)
  default     = {}
}
