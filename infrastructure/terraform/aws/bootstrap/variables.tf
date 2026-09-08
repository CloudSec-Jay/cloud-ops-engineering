variable "aws_region" {
  description = "AWS Region that owns the Terraform state foundation"
  default     = "us-east-1"
  type        = string
  nullable    = false

  validation {
    condition     = contains(["us-east-1", "us-east-2"], var.aws_region)
    error_message = "aws_region must be approved deployment Region"
  }
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform"
  type        = string
  nullable    = false

  validation {
    condition = (
      length(var.state_bucket_name) >= 3 &&
      length(var.state_bucket_name) <= 63 &&
      var.state_bucket_name == lower(trimspace(var.state_bucket_name))
    )
    error_message = "state_bucket_name must be 3-63 characters and lowercase."
  }
}