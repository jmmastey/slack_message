SlackMessage: a Friendly DSL for Slack
=============

SlackMessage is a wrapper over the [Block Kit
API](https://app.slack.com/block-kit-builder/) to make it easy to read and
write messages to slack in your ruby application.

Posting a message to Slack should be this easy:

```ruby
SlackMessage.post_to('#general') do
  text "We did it @here! :thumbsup:"
end
```

To install, just add `slack_message` to your bundle and you're ready to go.

Opinionated Stances
------------

Slack's API has a lot of options available to you! But this gem takes some
opinionated stances on how to make use of that API. For instance:

* No dependencies. Your lockfile is enough of a mess already.
* Webhooks are passé. Only Slack Apps are supported now.
* Unless you request otherwise, text is always rendered using `mrkdwn`. If you
  want plaintext, you'll need to ask for it. Same for the `emoji` flag.
* As many API semantics as possible are hidden. For instance, if you post to
  something that looks like an email address, `slack_message` is going to try to
  look it up as an email address.
* A few little hacks on the block syntax, such as adding a `blank_line` (which
  doesn't exist in the API), or leading spaces.
* Configuration is kept as simple as possible. But, as much heavy lifting as
  possible should occur just once via configuration and not on every call.

Usage
------------

### Configuration

To get started, you'll need to create a Slack App with some appropriate
permissions.  It used to be possible to use the Webhook API, but that's long
since been deprecated, and apps are pretty [straightforward to
create](https://api.slack.com/tutorials/tracks/getting-a-token).

Generally, make sure your token has permissions for `users:read` and `chat:write`.

```ruby
SlackMessage.configure do |config|
  api_token = 'xoxb-11111111111-2222222222-33333333333333333'

  config.add_profile(api_token: api_token)
end
```

You should keep your token in a safe place like `ENV`. If using this gem with
Rails, place this code in somewhere like `config/initializers/slack_message.rb`.

#### Additional Profiles

If your app uses slack messages for several different purposes, it's common to
want to post to different channels as different names / icons / etc. To do that
more easily and consistently, you can specify multiple profiles:

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

A number of parameters are available to make it simpler to use a profile without
specifying repetitive information. Most all have corresponding options when
composing a message:

| Config          | Default         | Value                                                           |
|-----------------|-----------------|-----------------------------------------------------------------|
| api_token       | None            | Your Slack App API Key.                                         |
| name            | From Slack App  | The bot name for your message.                                  |
| icon            | From Slack App  | Profile icon for your message. Specify as :emoji: or image URL. |
| default_channel | None (optional) | Channel / user to post to by default.                           |


Setting a `default_channel` specifically will allow you to use `post_as`, which
is a convenient shortcut for bots that repeatedly post to one channel as a
consistent identity:

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
are most useful to create consistent name / icon setups for apps with many bots.

### Posting Messages

As mentioned at the top, posting a message to Slack is dang easy:

```ruby
SlackMessage.post_to('#general') do
  text "We did it @here! :thumbsup:"
end
```

That's it! SlackMessage will automatically serialize for the API like this:

```json
[{"type":"section","text":{"type":"mrkdwn","text":"We did it @here! :thumbsup:"}}]
```

Details like remembering that Slack made a mystifying decision to force you to
request "mrkdwn", or requiring your text to be wrapped into a section are handled
for you. Building up messages is meant to be as user-friendly as possible:

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

It's just as easy to send messages directly to users. SlackMessage will look for
targets that are email-addressish, and look them up for you automatically:

```ruby
user_email = 'hello@joemastey.com'

SlackMessage.post_to(user_email) do
  text "You specifically did it! :thumbsup:"
end
```

SlackMessage is able to build all kinds of rich messages for you, and has been
a real joy to use for the author at least. To understand a bit more about the
possibilities of blocks, you should play around with Slack's [Block Kit
Builder](https://app.slack.com/block-kit-builder/). There are lots of options:

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
use for your message by specifying its name:

```ruby
SlackMessage.post_to('#general', as: :sidekiq_bot) do
  text ":octagonal_sign: A job has failed permanently and needs to be rescued."
  link_button "Sidekiq Dashboard", sidekiq_dashboard_url, style: :danger
end
```

You can also override profile bot details when sending a message:

```ruby
SlackMessage.post_to('#general') do
  bot_name "CoffeeBot"
  bot_icon ":coffee:"

  text ":coffee::clock: Time to take a break!"
end
```

#### Notifying Users

There are several supported ways to tag and notify users. Mentioned above, it's
possible to DM a user by email:

```ruby
SlackMessage.post_to('hello@joemastey.com') do
  text "Hi there!"
end
```

You can also mention a user by email within a channel by wrapping their name
in tags:

```ruby
SlackMessage.post_to('#general') do
  bot_name "CoffeeBot"
  bot_icon ":coffee:"

  text ":coffee: It's your turn to make coffee <hello@joemastey.com>."
end
```

Emails that are not wrapped in tags will be rendered as normal clickable email
addresses. Additionally, Slack will automatically convert a number of channel
names and tags you're probably already used to:

```ruby
SlackMessage.post_to('#general') do
  bot_name "CoffeeBot"
  bot_icon ":coffee:"

  text "@here there's no coffee left!"
end
```

By default, the desktop notification for a message will be the text of the 
message itself. However, you can customize desktop notifications if you prefer:

```ruby
SlackMessage.post_to('hello@joemastey.com') do
  bot_name "CoffeeBot"
  bot_icon ":coffee:"

  notification_text "It's a coffee emergency!"
  text "There's no coffee left!"
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

What it Doesn't Do
------------

This gem is intended to stay fairly simple. Other gems have lots of config
options and abilities, which is wonderful, but overall complicates usage. If
you want to add a feature, open an issue on Github first to see if it's likely
to be merged. This gem was built out of an existing need that _didn't_ include
most of the block API, but I'd be inclined to merge features that sustainably
expand the DSL to include more useful features.

Some behaviors that are still planned but not yet added:

* some API documentation amirite?
* custom http_options in configuration
* more of BlockKit's options
* any interactive elements at all
* editing / updating messages
* multiple recipients
* more interesting return types for your message
* richer text formatting (for instance, `ul` is currently a hack)

Contributing
------------

Contributions are very welcome. Fork, fix, submit pull.

Contribution is expected to conform to the [Contributor Covenant](https://github.com/jmmastey/slack_message/blob/master/CODE_OF_CONDUCT.md).

License
------------

This software is released under the [MIT License](https://github.com/jmmastey/slack_message/blob/master/MIT-LICENSE).
