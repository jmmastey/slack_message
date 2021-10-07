require 'spec_helper'

RSpec.describe SlackMessage do
  describe "API convenience" do
    it "can grab user IDs" do
      SlackMessage.configure { |c| c.api_token = "asdf" }
      allow(Net::HTTP).to receive(:start).and_return(
        double(code: "200", body: '{ "user": { "id": "ABC123" }}')
      )

      result = SlackMessage.user_id_for("hello@joemastey.com")
      expect(result).to eq("ABC123")
    end
  end

  describe "DSL" do
    describe "#build" do
      it "renders some JSON" do
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
    after do
      SlackMessage.configuration.reset
    end

    it "allows you to set an API key" do
      SlackMessage.configure do |config|
        config.api_token = "abc123"
      end

      expect(SlackMessage.configuration.api_token).to eq("abc123")
    end

    it "raises errors for missing configuration" do
      SlackMessage.configure do |config|
        #config.api_token = "abc123"
      end

      expect {
        SlackMessage.configuration.api_token
      }.to raise_error(ArgumentError)
    end

    it "lets you add and fetch profiles" do
      SlackMessage.configure do |config|
        config.add_profile(name: 'default profile', url: 'http://hooks.slack.com/1234/')
        config.add_profile(:nonstandard, name: 'another profile', url: 'http://hooks.slack.com/1234/')
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
        config.add_profile(name: 'default profile', url: 'http://hooks.slack.com/1234/')
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

    it "is not stateful" do
      expect {
        SlackMessage.post_to('#general') { text "foo" }
      }.to post_slack_message_to('#general')

      expect { }.not_to post_slack_message_to('#general')
    end
  end
end
