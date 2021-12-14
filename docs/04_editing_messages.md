### Updating a Previous Message

After you've posted a message, you may want to edit it later. Interactive bots,
for instance, may want to repeatedly update a message.

Posting will always return an object representing your posted message.

```ruby
message = SlackMessage.post_to('#general') do
  text "Getting ready..."
end
```

Then, you can use that response object to go back and rewrite the message a
little or a lot.

```ruby
SlackMessage.update(message) do
  text "Done!"
end
```

The new message contents will be built and updated via the API. To give an
example, you could alert slack to a job status by updating your original
message.


```ruby
class SomeWorker < ApplicationWorker
  def perform
    post_started_status

    # ... perform work here

    post_finished_status
  end

  private

  def post_started_status
    @message = SlackMessage.post_as(:job_worker) do
      text "Beginning upload."
    end
  end

  def post_finished_status
    SlackMessage.update(@message) do
      text "Finished upload! @here come and get it."
      link_button "See Results", uploaded_data_url
    end
  end
end
```

### Storing Response Objects for Later

Since updates are likely to occur after you've long since finished posting the
original message, you'll need to persist the message response somehow until you
need to update it later. As one option, you could serialize the response object
for later.

```ruby
# initially
message = SlackMessage.post_to('#general') do
  text "Starting..."
end
redis_connection.set(self.message_cache_key, Marshal.dump(message))


# later
message = Marshal.load(redis_connection.get(self.message_cache_key))
SlackMessage.update(message) do
  text "Finished!"
end
```

Alternatively, you could persist the relevant data into the database. A message
is identified to the API by a combination of its _channel_ and _timestamp_, and
you can use these identifiers rather than passing the response object itself.

```ruby
# initially
message = SlackMessage.post_to('#general') do
  text "Starting..."
end
UploadRun.create!(slack_channel: message.channel, slack_timestamp: message.timestamp)

## later
run = self.persisted_upload_run
message = SlackMessage.update(channel: run.slack_channel, timestamp: run.slack_timestamp) do
  text "Finished!"
end
```

See the [API documentation for
chat.update](https://api.slack.com/methods/chat.update) for more information on
updating messages.

---

Next: Deleting Messages
