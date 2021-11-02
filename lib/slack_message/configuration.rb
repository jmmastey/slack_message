module SlackMessage::Configuration
  @@profiles = {}

  def self.reset
    @@profiles  = {}
  end

  def self.configure
    yield self
  end

  ###

  def self.clear_profiles! # test harness, mainly
    @@profiles = {}
  end

  def self.add_profile(handle = :default, api_token:, name: nil, icon: nil, default_channel: nil)
    if @@profiles.include?(handle)
      warn "WARNING: Overriding profile '#{handle}' in SlackMessage config"
    end

    @@profiles[handle] = {
      handle: handle,
      api_token: api_token,
      name: name,
      icon: icon,
      default_channel: default_channel
    }
  end

  def self.profile(handle)
    unless @@profiles.include?(handle)
      raise ArgumentError, "Unknown SlackMessage profile '#{handle}'."
    end

    @@profiles[handle]
  end
end
