variable "project_name" {
    type = string
    default = "expense"
}

variable "environment" {
    type = string
    default = "dev"
}

variable "common_tags" {
    default = {
        Project = "Expense"
        Environment = "dev"
        Terraform = "true"
    }
}

variable "enable_blue" {
    type = bool
    default = true
}

variable "enable_green" {
    type = bool
    default = true
}

variable "eks_nodegroup_blue_version" {
    default = "1.35"
}

variable "eks_nodegroup_green_version" {
    default = "1.34"
}

variable "eks_version" {
    default = "1.35"
}