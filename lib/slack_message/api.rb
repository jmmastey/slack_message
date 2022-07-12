require 'net/http'
require 'net/https'
require 'json'

module SlackMessage::Api
  extend self

  def user_id_for(email, profile)
    unless email =~ SlackMessage::EMAIL_PATTERN
      raise ArgumentError, "Tried to find profile by invalid email address '#{email}'"
    end

    if SlackMessage::Configuration.debugging?
      warn [email, profile].inspect
    end

    response = look_up_user_by_email(email, profile)

    if response.code != "200"
      raise SlackMessage::ApiError, "Got an error back from the Slack API (HTTP #{response.code}):\n#{response.body}"
    elsif response.body == ""
      raise SlackMessage::ApiError, "Received empty 200 response from Slack when looking up user info. Check your API key."
    end

    SlackMessage::ErrorHandling.raise_user_lookup_response_errors(response, email, profile)

    payload = JSON.parse(response.body)

    payload["user"]["id"]
  end

  def post(payload, target, profile, time)
    params  = {
      channel: target,
      username: payload.custom_bot_name || profile[:name],
      blocks: payload.render,
      text: payload.custom_notification,
    }

    if params[:blocks].length == 0
      raise ArgumentError, "Tried to send an entirely empty message."
    end

    icon = payload.custom_bot_icon || profile[:icon]
    if icon =~ /^:\w+:$/
      params[:icon_emoji] = icon
    elsif icon =~ /^(https?:\/\/)?[0-9a-z]+\.[-_0-9a-z]+/ # very naive regex, I know. it'll be fine.
      params[:icon_url] = icon
    elsif !(icon.nil? || icon == '')
      raise ArgumentError, "Couldn't figure out icon '#{icon}'. Try :emoji: or a URL."
    end

    if !time.nil?
      params[:post_at] = time.to_i

      if payload.custom_bot_name || payload.custom_bot_icon
        raise ArgumentError, "Sorry, setting an image / emoji icon for scheduled messages isn't supported."
      end
    end

    if SlackMessage::Configuration.debugging?
      warn params.inspect
    end

    response = post_message(profile, params)

    SlackMessage::ErrorHandling.raise_post_response_errors(response, params, profile)
    SlackMessage::Response.new(response, profile[:handle])
  end

  def update(payload, message, profile)
    params  = {
      channel: message.channel,
      ts: message.timestamp,
      blocks: payload.render,
      text: payload.custom_notification
    }

    if params[:blocks].length == 0
      raise ArgumentError, "Tried to send an entirely empty message."
    end

    if SlackMessage::Configuration.debugging?
      warn params.inspect
    end

    response = update_message(profile, params)
    body  = JSON.parse(response.body)
    error = body.fetch("error", "")

    SlackMessage::ErrorHandling.raise_update_response_errors(response, params, profile)
    SlackMessage::Response.new(response, profile[:handle])
  end

  def delete(message, profile)
    params = if message.scheduled?
      {
        channel: message.channel,
        scheduled_message_id: message.scheduled_message_id,
      }
    else
      {
        channel: message.channel,
        ts: message.timestamp,
      }
    end

    if SlackMessage::Configuration.debugging?
      warn params.inspect
    end

    response = delete_message(profile, params)

    SlackMessage::ErrorHandling.raise_delete_response_errors(response, message, profile)
    response
  end

  private

  # mostly for test harnesses

  def look_up_user_by_email(email, profile)
    uri = URI("https://slack.com/api/users.lookupByEmail?email=#{email}")

    request = Net::HTTP::Get.new(uri).tap do |req|
      req['Authorization']  = "Bearer #{profile[:api_token]}"
      req['Content-type']   = "application/json; charset=utf-8"
    end

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end

  def post_message(profile, params)
    uri = if params.has_key?(:post_at)
      URI("https://slack.com/api/chat.scheduleMessage")
    else
      URI("https://slack.com/api/chat.postMessage")
    end

    request = Net::HTTP::Post.new(uri).tap do |req|
      req['Authorization']  = "Bearer #{profile[:api_token]}"
      req['Content-type']   = "application/json; charset=utf-8"
      req.body = params.to_json
    end

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end

  def update_message(profile, params)
    uri = URI("https://slack.com/api/chat.update")

    request = Net::HTTP::Post.new(uri).tap do |req|
      req['Authorization']  = "Bearer #{profile[:api_token]}"
      req['Content-type']   = "application/json; charset=utf-8"
      req.body = params.to_json
    end

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end

  def delete_message(profile, params)
    uri = if params.has_key?(:scheduled_message_id)
      URI("https://slack.com/api/chat.deleteScheduledMessage")
    else
      URI("https://slack.com/api/chat.delete")
    end

    request = Net::HTTP::Post.new(uri).tap do |req|
      req['Authorization']  = "Bearer #{profile[:api_token]}"
      req['Content-type']   = "application/json; charset=utf-8"
      req.body = params.to_json
    end

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end
end
