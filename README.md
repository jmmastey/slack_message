SlackMessage: a Friendly DSL for Slack
=============

SlackMessage is a wrapper over the [Block Kit
API](https://app.slack.com/block-kit-builder/) to make it easy to read and
write messages to slack in your ruby application. It has zero dependencies and
is built to be opinionated to keep your configuration needs low.

Posting a message to Slack should be this easy:

```ruby
SlackMessage.post_to('#general') do
  text "We did it @here! :thumbsup:"
end
```

To install, just add `slack_message` to your bundle and you're ready to go.


Usage
------------

### Configuration

To get started, you'll need to configure at least one profile to use to post
to slack. Get a [Webhook URL](https://slack.com/help/articles/115005265063-Incoming-webhooks-for-Slack)
from Slack and configure it like this:

```ruby
SlackMessage.configure do |config|
  webhook_url = 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX'

  config.add_profile(name: 'Slack Notifier', url: webhook_url)
end
```

You should probably keep that webhook in a safe place like `ENV`. If using this
gem with Rails, place this code in somewhere like
`config/initializers/slack_message.rb`.

#### Additional Profiles

If you want to post to multiple different webhook addresses (say, if you have
several different bots that post to different channels as different identities),
you can configure those profiles as well, by giving each of them a name:

```ruby
SlackMessage.configure do |config|
  # default profile
  config.add_profile(name: 'Slack Notifier', url: ENV['SLACK_WEBHOOK_URL'])

  # additional profiles (see below for usage)
  config.add_profile(:prod_alert_bot, name: 'Prod Alert Bot', url: ENV['SLACK_PROD_ALERT_WEBHOOK_URL'])
  config.add_profile(:sidekiq_bot, name: 'Sidekiq Bot', url: ENV['SLACK_SIDEKIQ_WEBHOOK_URL'])
end
```

If you frequently ping the same channel with the same bot, and don't want to
continually specify the channel name, you can specify a default channel and
post using the `post_as` method. It is otherwise identical to `post_to`, but
allows you to omit the channel argument:

```ruby
SlackMessage.configure do |config|
  config.add_profile(:prod_alert_bot,
    name: 'Prod Alert Bot',
    url: ENV['SLACK_PROD_ALERT_WEBHOOK_URL'],
    default_channel: '#red_alerts'
  )
end

SlackMessage.post_as(:prod_alert_bot) do
  text ":ambulance: weeooo weeooo something went wrong"
end
```

Note that `post_as` does not allow you to choose a channel (because that's just
the same as using `post_to`), so you really do have to specify `default_channel`.

#### Configuring User Search

Slack's API no longer allows you to send DMs to users by username. You need to
look up a user's internal ID and send to that ID. Thankfully, there is a lookup
by email endpoint for this. If you'd like to post messages to users by their
email address, you'll need a
[separate API Token](https://api.slack.com/tutorials/tracks/getting-a-token):

```ruby
SlackMessage.configure do |config|
  config.api_token = 'xoxb-11111111111-2222222222-33333333333333333'
end
```

### Posting Messages

As mentioned at the top, posting a message to Slack is dang easy:

```ruby
SlackMessage.post_to('#general') do
  text "We did it @here! :thumbsup:"
end
```

That's it! SlackMessage will automatically serialize for the API like this:

```json
[{"type":"section","text":{"type":"mrkdwn","text":"We did it! :thumbsup:"}}]
```

Details like remembering that Slack made a mystifying decision to force you to
request "mrkdwn", or requiring your text to be wrapped into a section are handled
for you.

Building up messages is meant to be as user-friendly as possible:

```ruby
SlackMessage.build do
  text "haiku are easy"
  text "but sometimes they don't make sense"
  text "refrigerator"

  context "- unknown author"
end
```

SlackMessage will combine your text declarations and add any necessary wrappers
automatically:

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

If you've configured an API key for user search (see above in configuration),
it's just as easy to send messages directly to users:

```ruby
SlackMessage.post_to('hello@joemastey.com') do
  text "We did it! :thumbsup:"
end
```

SlackMessage is able to build all kinds of rich messages for you, and has been
a real joy to use for the author at least. To understand a bit more about the
possibilities of blocks, see Slack's [Block Kit
Builder](https://app.slack.com/block-kit-builder/) to understand the structure
better. There are lots of options:

```ruby
SlackMessage.post_to('#general') do
  section do
    text "A job has generated some output for you to review."
    text 'And More' * 10
    link_button "See Results", "https://google.com"
  end

  section do
    text ":unlock-new: New Data Summary"

    list_item "Date", "09/05/2021"
    list_item "Total Imported", 45_004
    list_item "Total Errors", 5
  end

  divider

  section do
    text "See more here: #{link('result', 'https://google.com')}"
  end

  text ":rocketship: hello@joemastey.com"

  context ":custom_slack_emoji: An example footer *with some markdown*."
end
```

SlackMessage will compose this into Block Kit syntax and send it on its way!
For now you'll need to read a bit of the source code to get the entire API. Sorry,
working on it.

If you've defined multiple profiles in configuration, you can specify which to
use for your message by specifying their name:

```ruby
SlackMessage.post_to('#general', as: :sidekiq_bot) do
  text ":octagonal_sign: A job has failed permanently and needs to be rescued."
  link_button "Sidekiq Dashboard", "https://yoursite.com/sidekiq", style: :danger
end
```

You can also use a custom name when sending a message:

```ruby
SlackMessage.post_to('#general') do
  bot_name "CoffeeBot"

  text ":coffee::clock: Time to take a break!"
end
```

### Testing

You can do some basic testing against SlackMessage, at least if you use RSpec!
You'll need to require and include the testing behavior like this, in your
spec_helper file:

```ruby
require 'slack_message/rspec'

RSpec.configure do |config|
  include SlackMessage::RSpec

  # your other config
end
```

This will stop API calls for posting messages, and will allow you access to
some custom matchers:

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
  SlackMessage.post_to('#general') { text "foo" }
}.to post_to_slack
```

Be forewarned, I'm frankly not that great at more complicated RSpec matchers,
so I'm guessing there are some bugs. Also, because the content of a message
gets turned into a complex JSON object, matching against content isn't capable
of very complicated regexes.

Opinionated Stances
------------

Slack's API has a lot of options available to you! But this gem takes some
opinionated stances on how to make use of that API. For instance:

* Unless you request otherwise, text is always rendered using `mrkdwn`. If you
  want plaintext, you'll need to ask for it.
* Generally, same goes for the `emoji` flag on almost every text element.
* It's possible to ask for a `blank_line` in sections, even though that concept
  isn't real. In this case, a text line containing only an emspace is rendered.
* It's easy to configure a bot for consistent name / channel use. My previous
  use of SlackNotifier led to frequently inconsistent names.

What it Doesn't Do
------------

This gem is intended to stay fairly simple. Other gems have lots of config
options and abilities, which is wonderful, but overall complicates usage. If
you want to add a feature, open an issue on Github first to see if it's likely
to be merged.

Since this gem was built out of an existing need that _didn't_ include most of
the block API, I'd be inclined to merge features that sustainably expand the
DSL to include more of the block API itself.

Also, some behaviors that are still planned but not yet added:

* some API documentation amirite?
* allow custom http_options in configuration
* more of BlockKit's options
* any interactive elements at all (I don't understand them yet)
* more interesting return types for your message
* richer text formatting (ul is currently a hack)

Contributing
------------

Contributions are very welcome. Fork, fix, submit pulls.

Contribution is expected to conform to the [Contributor Covenant](https://github.com/jmmastey/slack_message/blob/master/CODE_OF_CONDUCT.md).

License
------------

This software is released under the [MIT License](https://github.com/jmmastey/slack_message/blob/master/MIT-LICENSE).
