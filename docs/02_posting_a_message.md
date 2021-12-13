## Posting Messages

As mentioned at the outset, posting a message to Slack is dang easy.

```ruby
SlackMessage.post_to('#general') do
  text "We did it @here! :thumbsup:"
end
```

That's it! SlackMessage will automatically serialize for the API.

```json
[{"type":"section","text":{"type":"mrkdwn","text":"We did it @here! :thumbsup:"}}]
```

Details like remembering that Slack made a mystifying decision to force you to
request "mrkdwn", or requiring your text to be wrapped into a section are
handled for you. Building up messages is meant to be as user-friendly as
possible.

```ruby
SlackMessage.build do
  text "haiku are easy"
  text "but sometimes they don't make sense"
  text "refrigerator"

  context "- unknown author"
end
```

SlackMessage will combine your text declarations and add any necessary wrappers
automatically.

```json
[
  {
    "type": "section",
    "text": {
      "type": "mrkdwn",
      "text": "haiku are easy\nbut sometimes they don't make sense\nrefrigerator"
    }
  },
  {
    "type": "context",
    "elements": [
      {
        "type": "mrkdwn",
        "text": "- unknown author"
      }
    ]
  }
]
```

### Direct Messages

It's just as easy to send messages directly to users. SlackMessage will look
for targets that are email-addressish, and look them up for you automatically.

```ruby
SlackMessage.post_to('hello@joemastey.com') do
  text "You specifically did it! :thumbsup:"
end
```

SlackMessage will compose this into Block Kit syntax and send it on its way!

### Multiple Profiles

If you've defined multiple profiles in configuration, you can specify which to
use for your message by specifying its name.

```ruby
SlackMessage.post_to('#general', as: :sidekiq_bot) do
  text ":octagonal_sign: A job has failed permanently and needs to be rescued."

  link_button "Sidekiq Dashboard", sidekiq_dashboard_url, style: :danger
end
```

You can also override profile bot details when sending a message.

```ruby
SlackMessage.post_to('#general') do
  bot_name "CoffeeBot"
  bot_icon ":coffee:"

  text ":coffee::clock: Time to take a break!"
end
```

Finally, if your profile specifies a `default_channel`, you can also post with
the `post_as` shorthand.

```ruby
SlackMessage.post_as(:coffeebot) do
  text ":coffee::clock: Time to take a break!"
end
```

### Scheduling a Message

To schedule a message, simply provide a `at` parameter to your post. Provide
either a time object that responds to `to_i`, or an integer that represents a
[unix timestamp](https://en.wikipedia.org/wiki/Unix_time) for the time at which
you want your message posted.

```ruby
SlackMessage.post_to('hello@joemastey.com', at: 20.seconds.from_now) do
  text "From the top of the key. :basketball:"
end

SlackMessage.post_as(:basketball_bot, at: 20.seconds.from_now) do
  text "Boom shakalaka! :explosion:"
end
```

Please note that scheduled messages can't specify a `bot_name` or `bot_icon`,
nor can they be scheduled more than 120 days into the future.

### Best Practices

Talk about having coherent methods that post a message, rather than a block
that includes lots of indirection or ternaries.

See the [API documentation for
chat.postMessage](https://api.slack.com/methods/chat.postMessage) or
[chat.scheduleMessage](https://api.slack.com/methods/chat.scheduleMessage) for
more information on posting messages.

Next: The SlackMessage DSL
