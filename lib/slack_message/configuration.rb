module SlackMessage::Configuration
  @@api_token = nil
  @@profiles = {}

  def self.reset
    @@api_token = nil
    @@profiles  = {}
  end

  def self.configure
    yield self
  end

  ###

  def self.api_token=(token)
    @@api_token = token
  end

  def self.api_token
    unless @@api_token.is_a? String
      raise ArgumentError, "Please set an API token to use API features."
    end

    @@api_token
  end

  ###

  def self.add_profile(handle = :default, name:, url:)
    if @@profiles.include?(handle)
      warn("WARNING: Overriding profile '#{handle}' in SlackMessage config")
    end

    @@profiles[handle] = { name: name, url: url, handle: handle }
  end

  def self.profile(handle)
    unless @@profiles.include?(handle)
      raise ArgumentError, "Unknown SlackMessage profile '#{handle}'."
    end

    @@profiles[handle]
  end
end
