class SlackMessage::ErrorHandling
  PERMISSIONS_ERRORS = ["token_revoked", "token_expired", "invalid_auth", "not_authed",
                        "team_access_not_granted", "no_permission", "missing_scope",
                        "not_allowed_token_type", "ekm_access_denied"]

  def self.raise_post_response_errors(response, params, profile)
    body  = JSON.parse(response.body)
    error = body.fetch("error", "")

    if error == "invalid_blocks"
      raise SlackMessage::ApiError, "Couldn't send Slack message because the request contained invalid blocks:\n#{JSON.pretty_generate(params[:blocks])}"
    elsif error == "invalid_blocks_format"
      raise SlackMessage::ApiError, "Couldn't send Slack message because blocks is not a valid JSON object or doesn't match the Block Kit syntax:\n#{JSON.pretty_generate(params[:blocks])}"
    elsif error == "channel_not_found"
      raise SlackMessage::ApiError, "Tried to send Slack message to non-existent channel or user '#{params[:channel]}'"

    # scheduling messages
    elsif error == "invalid_time"
      raise SlackMessage::ApiError, "Couldn't schedule Slack message because you requested an invalid time '#{params[:post_at]}'"
    elsif error == "time_in_past"
      raise SlackMessage::ApiError, "Couldn't schedule Slack message because you requested a time in the past (or too close to now) '#{params[:post_at]}'"
    elsif error == "time_too_far"
      raise SlackMessage::ApiError, "Couldn't schedule Slack message because you requested a time more than 120 days in the future '#{params[:post_at]}'"


    elsif PERMISSIONS_ERRORS.include?(error)
      raise SlackMessage::ApiError, "Couldn't send Slack message because the API key for profile '#{profile[:handle]}' is wrong, or the app has insufficient permissions (#{error})"
    elsif error == "message_too_long"
      raise SlackMessage::ApiError, "Tried to send Slack message, but the message was too long"
    elsif error == "invalid_arguments"
      raise SlackMessage::ApiError, "Tried to send Slack message with invalid payload"
    elsif ["rate_limited", "ratelimited"].include?(error)
      raise SlackMessage::ApiError, "Couldn't send Slack message because you've reached your rate limit"
    elsif response.code == "302"
      raise SlackMessage::ApiError, "Got 302 response while posting to Slack. Check your API key for profile '#{profile[:handle]}'"
    elsif response.code != "200"
      raise SlackMessage::ApiError, "Got an error back from the Slack API (HTTP #{response.code}):\n#{response.body}"
    elsif !(error.nil? || error == "")
      raise SlackMessage::ApiError, "Received error response from Slack during message posting:\n#{response.body}"
    end
  end

  def self.raise_update_response_errors(response, message, profile)
    body  = JSON.parse(response.body)
    error = body.fetch("error", "")

    if ["invalid_blocks", "invalid_blocks_format"].include?(error)
      raise SlackMessage::ApiError, "Couldn't update Slack message because the serialized message had an invalid format"
    elsif error == "channel_not_found"
      raise SlackMessage::ApiError, "Tried to update Slack message to non-existent channel or user '#{message.channel}'"

    elsif error == "message_not_found"
      raise SlackMessage::ApiError, "Tried to update Slack message, but the message wasn't found (timestamp '#{message.timestamp}' for channel '#{message.channel}'"
    elsif error == "cant_update_message"
      raise SlackMessage::ApiError, "Couldn't update message because the message type isn't able to be updated, or #{profile[:handle]} isn't allowed to update it"
    elsif error == "edit_window_closed"
      raise SlackMessage::ApiError, "Couldn't update message because it's too old"


    elsif PERMISSIONS_ERRORS.include?(error)
      raise SlackMessage::ApiError, "Couldn't update Slack message because the API key for profile '#{profile[:handle]}' is wrong, or the app has insufficient permissions (#{error})"
    elsif error == "message_too_long"
      raise SlackMessage::ApiError, "Tried to update Slack message, but the message was too long"
    elsif error == "invalid_arguments"
      raise SlackMessage::ApiError, "Tried to update Slack message with invalid payload"
    elsif ["rate_limited", "ratelimited"].include?(error)
      raise SlackMessage::ApiError, "Couldn't update Slack message because you've reached your rate limit"
    elsif response.code == "302"
      raise SlackMessage::ApiError, "Got 302 response while updating a message. Check your API key for profile '#{profile[:handle]}'"
    elsif response.code != "200"
      raise SlackMessage::ApiError, "Got an error back from the Slack API (HTTP #{response.code}):\n#{response.body}"
    elsif !(error.nil? || error == "")
      raise SlackMessage::ApiError, "Received error response from Slack during message update:\n#{response.body}"
    end
  end

  def self.raise_delete_response_errors(response, message, profile)
    body  = JSON.parse(response.body)
    error = body.fetch("error", "")

    if error == "channel_not_found"
      raise SlackMessage::ApiError, "Tried to delete Slack message in non-existent channel '#{message.channel}'"

    elsif error == "invalid_scheduled_message_id"
      raise SlackMessage::ApiError, "Can't delete message because the ID was invalid, or the message has already posted (#{message.scheduled_message_id})"
    elsif error == "message_not_found"
      raise SlackMessage::ApiError, "Tried to delete Slack message, but the message wasn't found (timestamp '#{message.timestamp}' for channel '#{message.channel}')"
    elsif error == "cant_delete_message"
      raise SlackMessage::ApiError, "Can't delete message because '#{profile[:handle]}' doesn't have permission to"
    elsif error == "compliance_exports_prevent_deletion"
      raise SlackMessage::ApiError, "Can't delete message because team compliance settings prevent it"


    elsif PERMISSIONS_ERRORS.include?(error)
      raise SlackMessage::ApiError, "Couldn't delete Slack message because the API key for profile '#{profile[:handle]}' is wrong, or the app has insufficient permissions (#{error})"
    elsif ["rate_limited", "ratelimited"].include?(error)
      raise SlackMessage::ApiError, "Couldn't delete Slack message because you've reached your rate limit"
    elsif response.code == "302"
      raise SlackMessage::ApiError, "Got 302 response while deleting a message. Check your API key for profile '#{profile[:handle]}'"
    elsif response.code != "200"
      raise SlackMessage::ApiError, "Got an error back from the Slack API (HTTP #{response.code}):\n#{response.body}"
    elsif !(error.nil? || error == "")
      raise SlackMessage::ApiError, "Received error response from Slack during message delete:\n#{response.body}"
    end
  end

  def self.raise_user_lookup_response_errors(response, email, profile)
    begin
      payload = JSON.parse(response.body)
    rescue
      raise SlackMessage::ApiError, "Unable to parse JSON response from Slack API\n#{response.body}"
    end

    error = payload["error"]

    if error == "users_not_found"
      raise SlackMessage::ApiError, "Couldn't find a user with the email '#{email}'"


    elsif PERMISSIONS_ERRORS.include?(error)
      raise SlackMessage::ApiError, "Couldn't look up users because the API key for profile '#{profile[:handle]}' is wrong, or the app has insufficient permissions (#{error})"
    elsif error
      raise SlackMessage::ApiError, "Received error response from Slack during user lookup:\n#{response.body}"
    elsif response.code == "302"
      raise SlackMessage::ApiError, "Got 302 response during user lookup. Check your API key for profile '#{profile[:handle]}'"
    elsif response.code != "200"
      raise SlackMessage::ApiError, "Got an error back from the Slack API (HTTP #{response.code}):\n#{response.body}"
    elsif !(error.nil? || error == "")
      raise SlackMessage::ApiError, "Received error response from Slack during user lookup:\n#{response.body}"
    end
  end
end
