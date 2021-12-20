class SlackMessage::Response
  attr_reader :channel, :timestamp, :profile_handle, :scheduled_message_id, :original_response

  def initialize(api_response, profile_handle)
    @original_response = JSON.parse(api_response.body)
    @ok = @original_response["ok"]
    @channel = @original_response["channel"]

    @timestamp = @original_response["ts"]
    @scheduled_message_id = @original_response["scheduled_message_id"]

    @profile_handle = profile_handle
  end

  def marshal_dump
    [ @profile_handle, @channel, @timestamp, @original_response, @ok, @original_response ]
  end

  def marshal_load(data)
    @profile_handle, @channel, @timestamp, @original_response, @ok, @original_response = data
  end

  def sent_to_user?
    channel =~ /^D.*/ # users are D for DM, channels start w/ C
  end

  def scheduled?
    !!scheduled_message_id
  end

  def inspect
    identifier = if scheduled?
      "scheduled_message_id=#{scheduled_message_id}"
    else
      "timestamp=#{timestamp}"
    end

    ok_msg = @ok ? "ok" : "error"

    "<SlackMessage::Response #{ok_msg} profile_handle=:#{profile_handle} channel=#{channel} #{identifier}>"
  end
end
