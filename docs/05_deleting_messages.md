### Deleting Messages

Deleting a message is much like editing a message, only simpler. Just like when
you edit a message, you'll need a reference to the message you posted.

*Important Note: It's not possible to delete a message sent directly to a user.
It's also not possible to delete a scheduled message once it's already posted.
Don't send anything you don't want your boss to read.*

```ruby
message = SlackMessage.post_to('#general') do
  text "Testing: #{SLACK_SECRET_KEY}"
end
```

Now you can simply call the `delete` method to make up for your mistakes.

```ruby
SlackMessage.delete(message)
```

As with editing a message, it's possible to persist messages to redis / your
database and remove them using the timestamp and channel of your message.

```ruby
# initially
message = SlackMessage.post_to('#general') do
  text "Testing: #{SLACK_SECRET_KEY}"
end
redis_connection.set(self.message_cache_key, Marshal.dump(message))


# later
message = Marshal.load(redis_connection.get(self.message_cache_key))
SlackMessage.delete(message)
```

See the [API documentation for
chat.delete](https://api.slack.com/methods/chat.delete) or
[chat.deleteScheduledMessage](https://api.slack.com/methods/chat.deleteScheduledMessage)
for more information on deleting messages.

---

Next: [Mentions / Notifying Users](https://jmmastey.github.io/slack_message/06_notifying_users)
