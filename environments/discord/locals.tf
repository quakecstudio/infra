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
