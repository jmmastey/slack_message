## Testing

You can do some basic testing against SlackMessage, at least if you use RSpec!
You'll need to require and include the testing behavior in your spec_helper
file.

```ruby
require 'slack_message/rspec'

RSpec.configure do |config|
  include SlackMessage::RSpec

  # your other config
end
```

This will prevent API calls from leaking in your tests, and will allow you
access to some custom matchers.

```ruby
expect {
  SlackMessage.post_to('#general') { text "foo" }
}.to post_slack_message_to('#general').with_content_matching(/foo/)

expect {
  SlackMessage.post_as(:schmoebot) { text "foo" }
}.to post_slack_message_as(:schmoebot)

expect {
  SlackMessage.post_as(:schmoebot) { text "foo" }
}.to post_slack_message_as('Schmoe Bot')

expect {
  SlackMessage.post_as(:schmoebot) { text "foo" }
}.to post_slack_message_with_icon(':schmoebot:')

expect {
  SlackMessage.post_as(:schmoebot) { text "foo" }
}.to post_slack_message_with_icon_matching(/gravatar/)

expect {
  SlackMessage.post_to('#general') { text "foo" }
}.to post_to_slack
```

Be forewarned, I'm frankly not that great at more complicated RSpec matchers,
so I'm guessing there are some bugs. Also, because the content of a message
gets turned into a complex JSON object, matching against content isn't capable
of very complicated regexes.
