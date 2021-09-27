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

  def self.user_id_for(email)
    Api::user_id_for(email)
  end

  def self.post_to(target, as: :default, &block)
    payload = Dsl.new.tap do |instance|
      instance.instance_eval(&block)
    end

    profile = Configuration.profile(as, custom_name: payload.custom_bot_name)
    target  = user_id_for(target) if target =~ /^\S{1,}@\S{2,}\.\S{2,}$/

    Api.post(payload.render, target, profile)
  end

  def self.build(&block)
    Dsl.new.tap do |instance|
      instance.instance_eval(&block)
    end.send(:render)
  end
end
