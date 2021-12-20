## Mentions / Notifying Users

There are several supported ways to tag and notify users. As mentioned
initially, it's possible to DM a user by their account email.

```ruby
SlackMessage.post_to('hello@joemastey.com') do
  text "Hi there!"
end
```

You can also mention a user by email within a channel by wrapping their name in
tags.

```ruby
SlackMessage.post_to('#general') do
  bot_name "CoffeeBot"
  bot_icon ":coffee:"

  text ":coffee: It's your turn to make coffee <hello@joemastey.com>."
end
```

Emails that are not wrapped in tags will be rendered as normal email addresses.
Additionally, Slack will automatically convert a number of channel names and
tags you're probably already used to.

```ruby
SlackMessage.post_to('#general') do
  bot_name "CoffeeBot"
  bot_icon ":coffee:"

  text "@here There's no coffee left! Let #general know when you fix it."
end
```

By default, the desktop notification for a message will be the text of the
message itself. However, you can customize desktop notifications if you prefer.

```ruby
SlackMessage.post_to('hello@joemastey.com') do
  bot_name "CoffeeBot"
  bot_icon ":coffee:"

  notification_text "It's a coffee emergency!"
  text "There's no coffee left!"
end
```

#### Using @channel or @here

Not really a feature, but Slack will respect usage of `@here` and `@channel`.

```ruby
SlackMessage.post_to('#general') do
  text "Hey @channel, don't forget to submit your drink requests."
end
```

---

Next: [Testing](https://jmmastey.github.io/slack_message/07_testing)
