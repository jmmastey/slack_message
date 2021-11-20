module SlackMessage
  require 'slack_message/dsl'
  require 'slack_message/api'
  require 'slack_message/configuration'

  class ApiError < RuntimeError; end

  def self.configuration
    Configuration
  end

  def self.configure(&block)
    configuration.configure(&block)
  end

  def self.user_id(email, profile_name = :default)
    profile = Configuration.profile(profile_name)
    Api.user_id_for(email, profile)
  end

  def self.post_to(target, as: :default, &block)
    profile = Configuration.profile(as)

    payload = Dsl.new(block, profile).tap do |instance|
      instance.instance_eval(&block)
    end

    target  = Api::user_id_for(target, profile) if target =~ /^\S{1,}@\S{2,}\.\S{2,}$/

    Api.post(payload, target, profile)
  end

  def self.post_as(profile_name, &block)
    profile = Configuration.profile(profile_name)
    if profile[:default_channel].nil?
      raise ArgumentError, "Sorry, you need to specify a default_channel for profile #{profile_name} to use post_as"
    end

    payload = Dsl.new(block, profile).tap do |instance|
      instance.instance_eval(&block)
    end

    target  = profile[:default_channel]
    target  = Api::user_id_for(target, profile) if target =~ /^\S{1,}@\S{2,}\.\S{2,}$/

    Api.post(payload, target, profile)
  end

  def self.build(profile_name = :default, &block)
    profile = Configuration.profile(profile_name)

    Dsl.new(block, profile).tap do |instance|
      instance.instance_eval(&block)
    end.send(:render)
  end
end
