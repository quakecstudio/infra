variable "aws_region" {
  description = "Region of the SSM parameter that holds the bot token."
  type        = string
  default     = "us-east-1"
}

variable "server_id" {
  description = "ID of the QuakeC Studio Discord server. Bots can't create servers, so it was created in the Discord client and the bot invited to it."
  type        = string
  default     = "1573736194028609587"
}
