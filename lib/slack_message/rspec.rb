require 'rspec/expectations'
require 'rspec/mocks'

# Honestly, this code is what happens when you do not understand the RSpec
# custom expectation API really at all, but you really want to create your
# matcher. This code is soo baaad.

module SlackMessage::RSpec
  extend RSpec::Matchers::DSL

  @@listeners = []

  def self.register_expectation_listener(expectation_instance)
    @@listeners << expectation_instance
  end

  def self.unregister_expectation_listener(expectation_instance)
    @@listeners.delete(expectation_instance)
  end

  FauxResponse = Struct.new(:code, :body)

  def self.included(_)
    SlackMessage::Api.singleton_class.undef_method(:execute_post_form)
    SlackMessage::Api.define_singleton_method(:execute_post_form) do |uri, params, profile|
      @@listeners.each do |listener|
        listener.record_call(params.merge(profile: profile, uri: uri))
      end

      return FauxResponse.new('200', 'ok')
    end
  end

  matcher :post_slack_message_to do |expected|
    match do |actual|
      @instance ||= PostTo.new
      @instance.with_channel(expected)

      actual.call
      @instance.enforce_expectations
    end

    chain :with_content_matching do |content_expectation|
      @instance ||= PostTo.new
      @instance.with_content_matching(content_expectation)
    end

    failure_message { @instance.failure_message }
    failure_message_when_negated { @instance.failure_message_when_negated }

    supports_block_expectations
  end

  class PostTo
    def initialize
      @captured_calls = []
      @content_expectation = nil
      @channel = nil

      SlackMessage::RSpec.register_expectation_listener(self)
    end

    def record_call(deets)
      @captured_calls.push(deets)
    end

    def with_channel(channel)
      @channel = channel
    end

    def with_content_matching(content_expectation)
      raise ArgumentError unless content_expectation.is_a? Regexp
      @content_expectation = content_expectation
    end

    def enforce_expectations
      SlackMessage::RSpec.unregister_expectation_listener(self)
      matching_messages.any? { |msg| body_matches_expectation?(msg.fetch(:blocks)) }
    end

    def matching_messages
      @captured_calls.select { |c| c[:channel] == @channel }
    end

    def body_matches_expectation?(sent)
      return true unless @content_expectation

      sent.to_s =~ @content_expectation
    end

    def failure_message
      if @content_expectation
        "expected block to post slack message to '#{@channel}' with content matching #{@content_expectation.inspect}"
      else
        "expected block to post slack message to '#{@channel}'"
      end
    end

    # TODO: does content_matching even make sense for negated test?
    def failure_message_when_negated
      if @content_expectation
        "expected block not to post slack message to '#{@channel}' with content matching #{@content_expectation.inspect}"
      else
        "expected block not to post slack message to '#{@channel}'"
      end
    end
  end
end
