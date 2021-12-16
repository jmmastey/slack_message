require 'spec_helper'

RSpec.describe SlackMessage do
  describe "DSL" do
    describe "#build" do
      it "renders some JSON" do
        SlackMessage.configure do |config|
          config.clear_profiles!
          config.add_profile(name: 'default profile', api_token: 'abc123')
        end

        expected_output = [
          { type: "section",
            text: { text: "foo", type: "mrkdwn" }
          }
        ]

        output = SlackMessage.build do
          text "foo"
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

    it "lets you assert notification text" do
      # TODO :|
    end

    it "can assert more generally too tbh" do
      expect {
        SlackMessage.post_to('#general') { text "foo" }
      }.to post_to_slack.with_content_matching(/foo/)
    end
  end

  describe "API convenience" do
    let(:profile) { SlackMessage::Configuration.profile(:default) }

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

  # describe delete
  # describe update
end
