require 'net/http'
require 'net/https'
require 'json'

class SlackMessage::Api
  def self.user_id_for(email, profile)
    uri = URI("https://slack.com/api/users.lookupByEmail?email=#{email}")
    request = Net::HTTP::Get.new(uri).tap do |req|
      req['Authorization']  = "Bearer #{profile[:api_token]}"
      req['Content-type']   = "application/json; charset=utf-8"
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
    params  = {
      channel: target,
      username: payload.custom_bot_name || profile[:name],
      blocks: payload.render,
      text: payload.notification_text,
    }

    icon = payload.custom_bot_icon || profile[:icon]
    if icon =~ /^:\w+:$/
      params[:icon_emoji] = icon
    elsif icon =~ /^(https?:\/\/)?[0-9a-z]+\.[-_0-9a-z]+/ # very naive regex, I know. it'll be fine.
      params[:icon_url] = icon
    elsif !(icon.nil? || icon == '')
      raise ArgumentError, "Couldn't figure out icon '#{icon}'. Try :emoji: or a URL."
    end

    response = post_message(profile, params)
    body  = JSON.parse(response.body)
    error = body.fetch("error", "")

    # let's try to be helpful about error messages
    if ["token_revoked", "token_expired", "invalid_auth", "not_authed"].include?(error)
      raise "Couldn't send slack message because the API key for profile '#{profile[:handle]}' is wrong."
    elsif ["no_permission", "ekm_access_denied"].include?(error)
      raise "Couldn't send slack message because the API key for profile '#{profile[:handle]}' isn't allowed to post messages."
    elsif error == "channel_not_found"
      raise "Tried to send Slack message to non-existent channel or user '#{target}'"
    elsif error == "invalid_arguments"
      raise "Tried to send Slack message with invalid payload."
    elsif response.code == "302"
      raise "Got 302 response while posting to Slack. Check your API key for profile '#{profile[:handle]}'."
    elsif response.code != "200"
      raise "Got an error back from the Slack API (HTTP #{response.code}):\n#{response.body}"
    end

    response
  end

  # mostly test harness
  def self.post_message(profile, params)
    uri = URI("https://slack.com/api/chat.postMessage")
    request = Net::HTTP::Post.new(uri).tap do |req|
      req['Authorization']  = "Bearer #{profile[:api_token]}"
      req['Content-type']   = "application/json; charset=utf-8"
      req.body = params.to_json
    end

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end

  private_class_method :post_message
end
