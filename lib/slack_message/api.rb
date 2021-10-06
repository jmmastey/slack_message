require 'net/http'
require 'net/https'
require 'json'

class SlackMessage::Api
  def self.user_id_for(email)
    token = SlackMessage.configuration.api_token

    uri = URI("https://slack.com/api/users.lookupByEmail?email=#{email}")
    request = Net::HTTP::Get.new(uri).tap do |req|
      req['Authorization']  = "Bearer #{token}"
      req['Content-type']   = "application/json"
    end

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code != "200"
      raise "Got an error back from the Slack API (HTTP #{response.code}):\n#{response.body}"
    elsif response.body == ""
      raise "Received empty 200 response from Slack when looking up user info. Check your API key."
    end

    begin
      payload = JSON.parse(response.body)
    rescue
      raise "Unable to parse JSON response from Slack API\n#{response.body}"
    end

    if payload.include?("error") && payload["error"] == "invalid_auth"
      raise "Received an error because your authentication token isn't properly configured:\n#{response.body}"
    elsif payload.include?("error")
      raise "Received error response from Slack during user lookup:\n#{response.body}"
    end

    payload["user"]["id"]
  end

  def self.post(payload, target, profile)
    profile[:url] = profile[:url]

    uri     = URI.parse(profile[:url])
    params  = {
      channel: target,
      username: profile[:name],
      blocks: payload
    }.to_json

    response = Net::HTTP.post_form uri, { payload: params }

    # let's try to be helpful about error messages
    if response.body == "invalid_token"
      raise "Couldn't send slack message because the URL for profile '#{profile[:handle]}' is wrong."
    elsif response.body == "channel_not_found"
      raise "Tried to send Slack message to non-existent channel or user '#{target}'"
    elsif response.body == "missing_text_or_fallback_or_attachments"
      raise "Tried to send Slack message with invalid payload."
    elsif response.code == "302"
      raise "Got 302 response while posting to Slack. Check your webhook URL for '#{profile[:handle]}'."
    elsif response.code != "200"
      raise "Got an error back from the Slack API (HTTP #{response.code}):\n#{response.body}"
    end

    response
  end
end
