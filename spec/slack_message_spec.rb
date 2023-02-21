require 'spec_helper'

RSpec.describe SlackMessage do

  describe "DSL" do
    describe "#build" do
      def outer_method
       "foo"
      end

      it "renders some JSON" do
        SlackMessage.configure do |config|
          config.clear_profiles!
          config.add_profile(name: 'default profile', api_token: 'abc123')
        end

        expected_output = [
          { type: "section",
            text: { text: "foo", type: "mrkdwn" }
          },
          { type: "section",
            text: { text: "foo", type: "mrkdwn" }
          },
        ]

        output = SlackMessage.build do
          text outer_method()
          section do
            text outer_method()
          end
        end

        expect(output).to eq(expected_output)
      end
    end
  end

  describe "configuration" do
    it "lets you add and fetch profiles" do
      SlackMessage.configure do |config|
        config.clear_profiles!
        config.add_profile(name: 'default profile', api_token: 'abc123')
        config.add_profile(:nonstandard, name: 'another profile', api_token: 'abc123')
      end

      expect(SlackMessage.configuration.profile(:default)[:name]).to eq('default profile')
      expect(SlackMessage.configuration.profile(:nonstandard)[:name]).to eq('another profile')

      expect {
        SlackMessage.configuration.profile(:missing)
      }.to raise_error(ArgumentError)
    end
  end

  describe "custom expectations" do
    before do
      SlackMessage.configure do |config|
        config.clear_profiles!
        config.add_profile(name: 'default profile', api_token: 'abc123')
      end
    end

    it "can assert expectations against posts" do
      expect {
        SlackMessage.post_to('#lieutenant') { text "foo" }
      }.not_to post_slack_message_to('#general')

      expect {
        SlackMessage.post_to('#general') { text "foo" }
      }.to post_slack_message_to('#general').with_content_matching(/foo/)
    end

    it "resets state properly" do
      expect {
        SlackMessage.post_to('#general') { text "foo" }
      }.to post_slack_message_to('#general')

      expect { }.not_to post_slack_message_to('#general')
    end

    it "lets you assert by profile name" do
      SlackMessage.configure do |config|
        config.clear_profiles!
        config.add_profile(:schmoebot, name: 'Schmoe', api_token: 'abc123', icon: ':schmoebot:', default_channel: '#schmoes')
      end

      expect {
        SlackMessage.post_as(:schmoebot) { text "foo" }
      }.to post_slack_message_to('#schmoes')

      expect {
        SlackMessage.post_as(:schmoebot) { text "foo" }
      }.to post_slack_message_as(:schmoebot)

      expect {
        SlackMessage.post_as(:schmoebot) { text "foo" }
      }.to post_slack_message_as('Schmoe').with_content_matching(/foo/)
    end

    it "lets you assert by profile image" do
      SlackMessage.configure do |config|
        config.clear_profiles!
        config.add_profile(:schmoebot, name: 'Schmoe', api_token: 'abc123', icon: ':schmoebot:', default_channel: '#schmoes')
      end

      expect {
        SlackMessage.post_as(:schmoebot) { text "foo" }
      }.to post_slack_message_with_icon(':schmoebot:')

      expect {
        SlackMessage.post_as(:schmoebot) do
          bot_icon ':schmalternate:'
          text "foo"
        end
      }.to post_slack_message_with_icon(':schmalternate:')

      expect {
        SlackMessage.post_as(:schmoebot) do
          bot_icon 'https://thispersondoesnotexist.com/image'
          text "foo"
        end
      }.to post_slack_message_with_icon_matching(/thisperson/)
    end

    it "can assert more generally too tbh" do
      expect {
        SlackMessage.post_to('#general') { text "foo" }
      }.to post_to_slack.with_content_matching(/foo/)
    end

    it "lets you send links with custom styles" do
      expect {
        SlackMessage.post_to('#general') do
          link_button 'Does this person exist?', 'https://thispersondoesnotexist.com/image', style: :danger
        end
      }.to post_to_slack.with_content_matching(/danger/)
    end
  end

  describe "API convenience" do
    before do
      SlackMessage.configure do |config|
        config.clear_profiles!
        config.add_profile(name: 'default profile', api_token: 'abc123')
      end
    end

    it "converts user IDs within text when tagged properly" do
      allow(SlackMessage::Api).to receive(:user_id_for).and_return('ABC123')

      expect {
        SlackMessage.post_to('#general') { text("Working: <hello@joemastey.com> ") }
      }.to post_to_slack.with_content_matching(/ABC123/)

      expect {
        SlackMessage.post_to('#general') { text("Not Tagged: hello@joemastey.com ") }
      }.to post_to_slack.with_content_matching(/hello@joemastey.com/)
    end

    it "is graceful about those failures" do
      allow(SlackMessage::Api).to receive(:user_id_for).with('nuffin@nuffin.nuffin', any_args).and_raise(SlackMessage::ApiError)
      allow(SlackMessage::Api).to receive(:user_id_for).with('hello@joemastey.com', any_args).and_return('ABC123')

      expect {
        SlackMessage.post_to('#general') { text("Not User: <nuffin@nuffin.nuffin>") }
      }.to post_to_slack.with_content_matching(/\<nuffin@nuffin.nuffin\>/)

      expect {
        SlackMessage.post_to('#general') { text("Not User: <nuffin@nuffin.nuffin>, User: <hello@joemastey.com>") }
      }.to post_to_slack.with_content_matching(/ABC123/)
    end
  end

  describe "error handling" do
    before do
      SlackMessage.configure do |config|
        config.clear_profiles!
        config.add_profile(name: 'default profile', api_token: 'abc123')
        config.add_profile(:schmoebot, name: 'Schmoe', api_token: 'abc123', icon: ':schmoebot:', default_channel: '#schmoes')
      end
    end

    after do
      SlackMessage::RSpec.reset_mock_response
    end

    it "raises for redirects" do
      SlackMessage::RSpec.respond_with(code: '302')

      expect {
        SlackMessage.post_to('#general') { text 'nuh uh' }
      }.to raise_error(SlackMessage::ApiError)
    end

    it "even raises errors during deletes" do
      message = SlackMessage.post_to('#general') { text 'nuh uh' }

      SlackMessage::RSpec.respond_with({'error' => 'bad choice'})

      expect {
        SlackMessage.delete(message)
      }.to raise_error(SlackMessage::ApiError)
    end

    shared_examples 'post api error message' do |error, error_message|
      it "responds to posts with error code '#{error}' with the expected message" do
        SlackMessage::RSpec.respond_with({'error' => error})

        expect {
          SlackMessage.post_to('#general') { text 'nuh uh' }
        }.to raise_error(SlackMessage::ApiError).with_message(error_message)

        expect {
          SlackMessage.post_as(:schmoebot) { text 'nuh uh' }
        }.to raise_error(SlackMessage::ApiError).with_message(error_message)
      end
    end

    shared_examples 'update api error message' do |error, error_message|
      it "responds to updates with error code '#{error}' with the expected message" do
        message = SlackMessage.post_to('#general') { text 'nuh uh' }

        SlackMessage::RSpec.respond_with({'error' => error})

        expect {
          SlackMessage.update(message) { text 'nuh uh' }
        }.to raise_error(SlackMessage::ApiError).with_message(error_message)
      end
    end

    shared_examples 'delete api error message' do |error, error_message|
      it "responds to updates with error code '#{error}' with the expected message" do
        message = SlackMessage.post_to('#general') { text 'nuh uh' }

        SlackMessage::RSpec.respond_with({'error' => error})

        expect {
          SlackMessage.delete(message)
        }.to raise_error(SlackMessage::ApiError).with_message(error_message)
      end
    end

    shared_examples 'block api error message' do |error, error_message|
      include_examples 'post api error message', error, error_message
      include_examples 'update api error message', error, error_message
    end

    include_examples 'block api error message', 'nuffin', /Received error response 'nuffin' from Slack/
    include_examples 'block api error message', 'invalid_blocks', /because the request contained invalid blocks:\n\[Enable debugging in configuration to view block data\.\]/
    include_examples 'block api error message', 'invalid_blocks_format', /because blocks is not a valid JSON object or doesn't match the Block Kit syntax:\n\[Enable debugging in configuration to view block data\.\]/
    include_examples 'block api error message', 'channel_not_found', /Slack message to non-existent channel or user/
    include_examples 'block api error message', 'invalid_auth', /because the API key for profile '.*' is wrong, or the app has insufficient permissions \(invalid_auth\)/
    include_examples 'block api error message', 'message_too_long', /but the message was too long/
    include_examples 'block api error message', 'invalid_arguments', /with invalid payload/
    include_examples 'block api error message', 'rate_limited', /because you've reached your rate limit/

    # Scheduling messages
    include_examples 'post api error message', 'invalid_time', /because you requested an invalid time/
    include_examples 'post api error message', 'time_in_past', /because you requested a time in the past \(or too close to now\)/
    include_examples 'post api error message', 'time_too_far', /because you requested a time more than 120 days in the future/

    # Updating messages
    include_examples 'update api error message', 'message_not_found', /but the message wasn't found/

    # Deleting messages
    include_examples 'delete api error message', 'nuffin', /Received error response 'nuffin' from Slack/
    include_examples 'delete api error message', 'invalid_scheduled_message_id', /Can't delete message because the ID was invalid, or the message has already posted/
    include_examples 'delete api error message', 'message_not_found', /but the message wasn't found/
    include_examples 'delete api error message', 'cant_delete_message', /Can't delete message because 'default' doesn't have permission to/
    include_examples 'delete api error message', 'compliance_exports_prevent_deletion', /Can't delete message because team compliance settings prevent it/
    include_examples 'delete api error message', 'invalid_auth', /because the API key for profile '.*' is wrong, or the app has insufficient permissions \(invalid_auth\)/
    include_examples 'delete api error message', 'rate_limited', /because you've reached your rate limit/
  end
end
