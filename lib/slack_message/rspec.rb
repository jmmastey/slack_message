require 'rspec/expectations'
require 'rspec/mocks'

# Honestly, this code is what happens when you do not understand the RSpec
# custom expectation API really at all, but you really want to create your
# matcher. This code is soo baaad.
#
# We override API calls by entirely replacing the low-level API method. Then we
# use our overridden version to capture and record calls. When someone creates
# a new expectation, an object is created, so we allow that object to register
# itself to receive notification when a slack message _would have_ been posted.
#
# Then once the expectation is fulfilled, that class unregisters itself so that
# it can be cleaned up properly.
#

# TODO: test helpers for scheduled messages, editing and deleting, and
# notification text. And realistically, overhaul all this.

module SlackMessage::RSpec
  extend RSpec::Matchers::DSL

  @@listeners = []
  @@custom_response = {}
  @@response_code = '200'

  def self.register_expectation_listener(expectation_instance)
    @@listeners << expectation_instance
  end

  def self.unregister_expectation_listener(expectation_instance)
    @@listeners.delete(expectation_instance)
  end

  def self.reset_custom_responses
    @@custom_response = {}
    @@response_code = '200'
  end

  FauxResponse = Struct.new(:code, :body)

  def self.included(_)
    SlackMessage::Api.undef_method(:post_message)
    SlackMessage::Api.define_singleton_method(:post_message) do |profile, params|
      @@listeners.each do |listener|
        listener.record_call(params.merge(profile: profile))
      end

      response = {
       "ok" => true,
       "channel" => "C12345678",
       "ts" => "1635863996.002300",
       "message" => { "type"=>"message", "subtype"=>"bot_message",
                     "text"=>"foo",
                     "ts"=>"1635863996.002300",
                     "username"=>"SlackMessage",
                     "icons"=>{"emoji"=>":successkid:"},
                     "bot_id"=>"B1234567890",
                     "blocks"=> [{"type"=>"section",
                                  "block_id"=>"hAh7",
                                  "text"=>{"type"=>"mrkdwn", "text"=>"foo", "verbatim"=>false}}
                     ]
       }
      }.merge(@@custom_response).to_json

      return FauxResponse.new(@@response_code, response)
    end

    SlackMessage::Api.undef_method(:look_up_user_by_email)
    SlackMessage::Api.define_singleton_method(:look_up_user_by_email) do |email, profile|
      response = {"ok"=>true, "user"=>{"id"=>"U5432CBA"}}
      return FauxResponse.new('200', response.to_json)
    end
  end

  def self.respond_with(response = {}, code: '200')
    raise ArgumentError, "custom response must be a hash" unless response.is_a? Hash

    @@custom_response = response
    @@response_code = code
  end

  def self.reset_mock_response
    @@custom_response = {}
    @@response_code = '200'
  end

  # w/ channel
  matcher :post_slack_message_to do |expected|
    match do |actual|
      @instance ||= PostTo.new
      @instance.with_channel(expected)

      actual.call
      @instance.enforce_expectations
    end

    chain :with_content_matching do |content|
      @instance ||= PostTo.new
      @instance.with_content_matching(content)
    end

    failure_message { @instance.failure_message }
    failure_message_when_negated { @instance.failure_message_when_negated }

    supports_block_expectations
  end

  # no channel
  matcher :post_to_slack do |expected|
    match do |actual|
      @instance ||= PostTo.new

      actual.call
      @instance.enforce_expectations
    end

    chain :with_content_matching do |content|
      @instance ||= PostTo.new
      @instance.with_content_matching(content)
    end

    failure_message { @instance.failure_message }
    failure_message_when_negated { @instance.failure_message_when_negated }

    supports_block_expectations
  end

  # name / profile matcher
  matcher :post_slack_message_as do |expected|
     match do |actual|
      @instance ||= PostTo.new
      @instance.with_profile(expected)

      actual.call
      @instance.enforce_expectations
    end

    chain :with_content_matching do |content|
      @instance ||= PostTo.new
      @instance.with_content_matching(content)
    end

    failure_message { @instance.failure_message }
    failure_message_when_negated { @instance.failure_message_when_negated }

    supports_block_expectations
  end

  # icon matcher
  matcher :post_slack_message_with_icon do |expected|
     match do |actual|
      @instance ||= PostTo.new
      @instance.with_icon(expected)

      actual.call
      @instance.enforce_expectations
    end

    chain :with_content_matching do |content|
      @instance ||= PostTo.new
      @instance.with_content_matching(content)
    end

    failure_message { @instance.failure_message }
    failure_message_when_negated { @instance.failure_message_when_negated }

    supports_block_expectations
  end

  matcher :post_slack_message_with_icon_matching do |expected|
     match do |actual|
      @instance ||= PostTo.new
      @instance.with_icon_matching(expected)

      actual.call
      @instance.enforce_expectations
    end

    chain :with_content_matching do |content|
      @instance ||= PostTo.new
      @instance.with_content_matching(content)
    end

    failure_message { @instance.failure_message }
    failure_message_when_negated { @instance.failure_message_when_negated }

    supports_block_expectations
  end

  class PostTo
    def initialize
      @captured_calls = []
      @content = nil
      @channel = nil
      @profile = nil
      @icon = nil
      @icon_matching = nil

      SlackMessage::RSpec.register_expectation_listener(self)
    end

    def record_call(deets)
      @captured_calls.push(deets)
    end

    def with_channel(channel)
      @channel = channel
    end

    def with_icon(icon)
      @icon = icon
    end

    def with_icon_matching(icon)
      raise ArgumentError unless icon.is_a? Regexp
      @icon_matching = icon
    end

    def with_content_matching(content)
      raise ArgumentError unless content.is_a? Regexp
      @content = content
    end

    def with_profile(profile)
      @profile = profile
    end

    def enforce_expectations
      SlackMessage::RSpec.unregister_expectation_listener(self)

      @captured_calls
        .select { |call| !@channel || call[:channel] == @channel }
        .select { |call| !@profile || [call[:profile][:handle], call[:username]].include?(@profile) }
        .select { |call| !@content || call.fetch(:blocks).to_s =~ @content }
        .select { |call| !@icon || call.fetch(:icon_emoji, call.fetch(:icon_url, '')) == @icon }
        .select { |call| !@icon_matching || call.fetch(:icon_emoji, call.fetch(:icon_url, '')) =~ @icon_matching }
        .any?
    end

    def failure_message
      "expected block to #{failure_expression}"
    end

    def failure_message_when_negated
      "expected block not to #{failure_expression}"
    end

    def failure_expression
      concat = []

      if @channel
        concat << "post a slack message to '#{@channel}'"
      elsif @profile
        concat << "post a slack message as '#{@profile}'"
      elsif @icon
        concat << "post a slack message with icon '#{@icon}'"
      elsif @icon_matching
        concat << "post a slack message with icon matching '#{@icon_matching.inspect}'"
      else
        concat << "post a slack message"
      end

      if @content
        concat << "with content matching #{@content.inspect}"
      end

      concat.join " "
    end
  end
end
