## Getting Started / Configuration

To get started sending messages, you'll first need to create a Slack App with
some appropriate permissions. It used to be possible to use the Webhook API,
but that's long since been deprecated, and apps are pretty [straightforward to
create](https://api.slack.com/tutorials/tracks/getting-a-token).

Generally, make sure your token has permissions for _at least_ `users:read` and
`chat:write`. Then, define a default profile for SlackMessage to use for
posting.

```ruby
SlackMessage.configure do |config|
  api_token = 'xoxb-11111111111-2222222222-33333333333333333'

  config.add_profile(api_token: api_token)
end
```

You should keep your token in a safe place like `ENV`. If using this gem with
Rails, place this code in somewhere like
`config/initializers/slack_message.rb`.

### Additional Profiles

If your app uses slack messages for several different purposes, it's common to
want to post to different channels as different names / icons / etc. To do that
more easily and consistently, you can specify multiple profiles.

```ruby
SlackMessage.configure do |config|
  api_token = 'xoxb-11111111111-2222222222-33333333333333333'

  # default profile
  config.add_profile(api_token: api_token, name: 'Slack Notifier')

  # additional profiles (see below for usage)
  config.add_profile(:prod_alert_bot,
    name: 'Prod Alert Bot'
    icon: ':mooseandsquirrel:'
  )
  config.add_profile(:sidekiq_bot,
    api_token: ENV.fetch('SIDEKIQ_SLACK_APP_API_TOKEN'),
    name: 'Sidekiq Bot',
  )
end
```

A number of parameters are available to make it simpler to use a profile
without specifying repetitive information. You can generally also specify this
information on a per-message basis.

| Config          | Default         | Value                                                           |
|-----------------|-----------------|-----------------------------------------------------------------|
| api_token       | None            | Your Slack App API Key.                                         |
| name            | From Slack App  | The bot name for your message.                                  |
| icon            | From Slack App  | Profile icon for your message. Specify as :emoji: or image URL. |
| default_channel | None (optional) | Channel / user to post to by default.                           |


Setting a `default_channel` specifically will allow you to use `post_as`, which
is a convenient shortcut for bots that repeatedly post to one channel as a
consistent identity.

```ruby
SlackMessage.configure do |config|
  config.add_profile(:red_alert_bot,
    api_token: ENV.fetch('SLACK_API_TOKEN'),
    name: 'Red Alerts',
    icon: ':klaxon:',
    default_channel: '#red_alerts'
  )
end

SlackMessage.post_as(:red_alert_bot) do
  text ":ambulance: weeooo weeooo something went wrong"
end
```

There's no reason you can't use the same API key for several profiles. Profiles
are most useful to create consistent name / icon setups for apps with many
bots.

### Debug Mode

If you'd like to get more information about the messages you send, you can set
SlackMessage to debug mode.

```ruby
SlackMessage.configure do |config|
  config.debug
end
```

You will now see warnings detailing all params sent to the API.

```ruby
  {
    :channel=>"#general",
    :username=>"Builds",
    :blocks=>[
      {:type=>"section", :text=>{
        :type=>"mrkdwn",
        :text=>"Build Stability is Looking Ruff :dog:"
      }}
    ],
    :text=>"Build Issues",
    :post_at=>1639421171,
  }
```

Note this includes data that is not included in `SlackMessage.build`.

---

Next: Posting a Message
