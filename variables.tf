
variable "lambda_timeout" {
  description = "Timeout in seconds for the Lambda function"
  type        = number
  default     = 30
}

variable "lambda_memory" {
  description = "Memory allocation in MB for the Lambda function"
  type        = number
  default     = 128
}
