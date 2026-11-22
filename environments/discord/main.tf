# Discord doesn't let bots create servers, so this adopts the server the bot
# was invited to. Settings not listed here stay as set in the Discord client.
resource "discord_server_settings" "main" {
  server_id                     = var.server_id
  name                          = "QuakeC Studio"
  verification_level            = "medium"
  default_message_notifications = "only_mentions"
  explicit_content_filter       = "all_members"
  system_channel_id             = discord_text_channel.general.id
}

# Discord's defaults for @everyone include CREATE_INSTANT_INVITE, MENTION_EVERYONE
# and voice permissions. This lists what everyone can do instead; channels
# narrow it further with overwrites.
resource "discord_role_everyone" "everyone" {
  server_id = var.server_id
  permissions = provider::discord::permissions([
    "VIEW_CHANNEL",
    "READ_MESSAGE_HISTORY",
    "SEND_MESSAGES",
    "SEND_MESSAGES_IN_THREADS",
    "CREATE_PUBLIC_THREADS",
    "ADD_REACTIONS",
    "EMBED_LINKS",
    "ATTACH_FILES",
    "USE_EXTERNAL_EMOJIS",
    "USE_APPLICATION_COMMANDS",
    "CHANGE_NICKNAME",
  ])
}

resource "discord_role" "maintainer" {
  server_id   = var.server_id
  name        = "Maintainer"
  color       = provider::discord::color("#E67E22")
  hoist       = true
  mentionable = true
  permissions = provider::discord::permissions([
    "KICK_MEMBERS",
    "BAN_MEMBERS",
    "MODERATE_MEMBERS",
    "MANAGE_MESSAGES",
    "MANAGE_THREADS",
    "PIN_MESSAGES",
    "MENTION_EVERYONE",
    "VIEW_AUDIT_LOG",
    "CREATE_EVENTS",
    "MANAGE_EVENTS",
  ])
}

resource "discord_role" "contributor" {
  server_id   = var.server_id
  name        = "Contributor"
  color       = provider::discord::color("#3498DB")
  hoist       = true
  mentionable = false
}

# Highest first. Both sit below the bot's own role, which Discord created when
# the bot joined.
resource "discord_role_positions" "main" {
  server_id = var.server_id
  role_ids = [
    discord_role.maintainer.id,
    discord_role.contributor.id,
  ]
}
