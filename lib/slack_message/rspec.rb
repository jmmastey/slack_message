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

  class PostTo
    def initialize
      @captured_calls = []
      @content = nil
      @channel = nil
      @profile = nil

      SlackMessage::RSpec.register_expectation_listener(self)
    end

    def record_call(deets)
      @captured_calls.push(deets)
    end

    def with_channel(channel)
      @channel = channel
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
        .filter { |call| !@channel || call[:channel] == @channel }
        .filter { |call| !@profile || [call[:profile], call[:username]].include?(@profile) }
        .filter { |call| !@content || call.fetch(:blocks).to_s =~ @content }
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
