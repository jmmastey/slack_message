require 'net/http'
require 'net/https'

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

    user = JSON.parse(response.body)
    user["user"]["id"]
  end

  def self.post(payload, target, profile)
    uri     = URI.parse(profile[:url])
    params  = {
      channel: target,
      username: profile[:name],
      blocks: payload
    }.to_json

    Net::HTTP.post_form uri, { payload: params }
  end
end
