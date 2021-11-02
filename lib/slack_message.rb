module SlackMessage
  require 'slack_message/dsl'
  require 'slack_message/api'
  require 'slack_message/configuration'

  def self.configuration
    Configuration
  end

  def self.configure(&block)
    configuration.configure(&block)
  end

  def self.post_to(target, as: :default, &block)
    payload = Dsl.new(block).tap do |instance|
      instance.instance_eval(&block)
    end

    profile = Configuration.profile(as)
    target  = Api::user_id_for(target, profile) if target =~ /^\S{1,}@\S{2,}\.\S{2,}$/

    Api.post(payload, target, profile)
  end

  def self.post_as(profile_name, &block)
    payload = Dsl.new(block).tap do |instance|
      instance.instance_eval(&block)
    end

    profile = Configuration.profile(profile_name)
    if profile[:default_channel].nil?
      raise ArgumentError, "Sorry, you need to specify a default_channel for profile #{profile_name} to use post_as"
    end

    target  = profile[:default_channel]
    target  = Api::user_id_for(target, profile) if target =~ /^\S{1,}@\S{2,}\.\S{2,}$/

    Api.post(payload, target, profile)
  end

  def self.build(&block)
    Dsl.new(block).tap do |instance|
      instance.instance_eval(&block)
    end.send(:render)
  end
end
