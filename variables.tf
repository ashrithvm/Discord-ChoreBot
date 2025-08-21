# variables.tf

variable "discord_bot_token" {
  description = "The token for the Discord bot"
  type        = string
  sensitive   = true # This prevents Terraform from showing the value in logs
}

variable "discord_channel_id" {
  description = "The ID of the Discord channel to post messages in"
  type        = string
}