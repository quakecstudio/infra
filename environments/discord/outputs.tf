output "invite_url" {
  description = "Permanent invite to the server, for the website and READMEs."
  value       = discord_invite.website.url
}
