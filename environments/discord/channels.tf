resource "discord_category_channel" "information" {
  server_id = var.server_id
  name      = "Information"
}

resource "discord_category_channel" "community" {
  server_id = var.server_id
  name      = "Community"
}

resource "discord_category_channel" "development" {
  server_id = var.server_id
  name      = "Development"
}

resource "discord_category_channel" "maintainers" {
  server_id = var.server_id
  name      = "Maintainers"

  # Hidden from the moment it's created; the overwrites below keep it that way.
  initial_permission_overwrites = [
    {
      id   = var.server_id
      type = "role"
      deny = provider::discord::permissions(["VIEW_CHANNEL"])
    },
  ]
}

# Information

resource "discord_text_channel" "welcome" {
  server_id   = var.server_id
  name        = "welcome"
  category_id = discord_category_channel.information.id
  topic       = "QuakeC Studio: an editor for QuakeC. https://www.quakecstudio.com"
}

resource "discord_text_channel" "announcements" {
  server_id   = var.server_id
  name        = "announcements"
  category_id = discord_category_channel.information.id
  topic       = "Releases and project news."
}

# Community

resource "discord_text_channel" "general" {
  server_id   = var.server_id
  name        = "general"
  category_id = discord_category_channel.community.id
  topic       = "Talk about QuakeC, Quake modding and QuakeC Studio."
}

resource "discord_forum_channel" "help" {
  server_id            = var.server_id
  name                 = "help"
  category_id          = discord_category_channel.community.id
  topic                = "One post per question. Include your OS, the QuakeC Studio version and what you tried."
  default_sort_order   = "latest_activity"
  default_forum_layout = "list_view"

  default_reaction_emoji = {
    emoji_name = "👍"
  }

  available_tags = [
    { name = "question", emoji_name = "❓" },
    { name = "bug", emoji_name = "🐛" },
    { name = "install", emoji_name = "📦" },
    { name = "solved", emoji_name = "✅", moderated = true },
  ]
}

resource "discord_text_channel" "showcase" {
  server_id   = var.server_id
  name        = "showcase"
  category_id = discord_category_channel.community.id
  topic       = "Share mods and projects you've built."
}

# Development

resource "discord_text_channel" "development" {
  server_id   = var.server_id
  name        = "development"
  category_id = discord_category_channel.development.id
  topic       = "Working on QuakeC Studio itself. Code lives at https://github.com/quakecstudio"
}

# Maintainers

resource "discord_text_channel" "maintainers" {
  server_id   = var.server_id
  name        = "maintainers"
  category_id = discord_category_channel.maintainers.id

  initial_permission_overwrites = [
    {
      id   = var.server_id
      type = "role"
      deny = provider::discord::permissions(["VIEW_CHANNEL"])
    },
  ]
}

# Permissions

locals {
  # Everyone can read these channels; only maintainers post.
  read_only_channels = {
    welcome       = discord_text_channel.welcome.id
    announcements = discord_text_channel.announcements.id
  }

  private_channels = {
    maintainers_category = discord_category_channel.maintainers.id
    maintainers          = discord_text_channel.maintainers.id
  }
}

resource "discord_channel_permission" "read_only_everyone" {
  for_each = local.read_only_channels

  channel_id   = each.value
  overwrite_id = var.server_id
  type         = "role"
  deny = provider::discord::permissions([
    "SEND_MESSAGES",
    "SEND_MESSAGES_IN_THREADS",
    "CREATE_PUBLIC_THREADS",
  ])
}

resource "discord_channel_permission" "read_only_maintainer" {
  for_each = local.read_only_channels

  channel_id   = each.value
  overwrite_id = discord_role.maintainer.id
  type         = "role"
  allow        = provider::discord::permissions(["SEND_MESSAGES"])
}

resource "discord_channel_permission" "private_everyone" {
  for_each = local.private_channels

  channel_id   = each.value
  overwrite_id = var.server_id
  type         = "role"
  deny         = provider::discord::permissions(["VIEW_CHANNEL"])
}

resource "discord_channel_permission" "private_maintainer" {
  for_each = local.private_channels

  channel_id   = each.value
  overwrite_id = discord_role.maintainer.id
  type         = "role"
  allow        = provider::discord::permissions(["VIEW_CHANNEL"])
}

# Ordering, top to bottom as in the Discord client: the categories, then the
# channels inside each.

resource "discord_channel_positions" "categories" {
  server_id = var.server_id
  channel_ids = [
    discord_category_channel.information.id,
    discord_category_channel.community.id,
    discord_category_channel.development.id,
    discord_category_channel.maintainers.id,
  ]
}

resource "discord_channel_positions" "information" {
  server_id = var.server_id
  channel_ids = [
    discord_text_channel.welcome.id,
    discord_text_channel.announcements.id,
  ]
}

resource "discord_channel_positions" "community" {
  server_id = var.server_id
  channel_ids = [
    discord_text_channel.general.id,
    discord_forum_channel.help.id,
    discord_text_channel.showcase.id,
  ]
}

# A permanent invite for the website and README links.
resource "discord_invite" "website" {
  channel_id = discord_text_channel.welcome.id
  max_age    = 0
}
