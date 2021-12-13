### Deleting Messages

Deleting a message is much like editing a message, only simpler. Just like when
you edit a message, you'll need a reference to the message you posted.

```ruby
message = SlackMessage.post_to('#general') do
  text "Testing: #{SLACK_SECRET_KEY}"
end
```

Now you can simply call the `remove` method to make up for your mistakes.

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

Note that the message timestamp is _absolutely required_. There's no current
way in SlackMessage to search for a message to delete.

See the [API documentation for
chat.delete](https://api.slack.com/methods/chat.delete) for more information on
deleting messages.

Next: Notifying Users
