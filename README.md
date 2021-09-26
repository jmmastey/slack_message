Slack Message - A Friendly DSL for Building Messages
=============

A friendly little DSL to build (and send) rich Slack messages using the block
API. Designed to require zero dependencies and to make maintaining your Slack
integration easy.

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
  config.add_profile(name: 'Slack Notifier', url: ENV['SLACK_WEBHOOK_URL'])
  config.add_profile(:prod_alert_bot, name: 'Prod Alert Bot', url: ENV['SLACK_PROD_ALERT_WEBHOOK_URL'])
  config.add_profile(:sidekiq_bot, name: 'Sidekiq Bot', url: ENV['SLACK_SIDEKIQ_WEBHOOK_URL'])
end
```

See below for usage of multiple profiles.

#### Searching for Users

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

### Usage

Basic usage is pretty straightforward:

```ruby
SlackMessage.post_to('#general') do
  text "We did it! :thumbsup:"
end
```

That's it! If you configured an API token for user lookup (see Searching for Users
above), then sending messages to individual users is just as simple:

```ruby
SlackMessage.post_to('hello@joemastey.com') do
  text "We did it! :thumbsup:"
end
```

But the real joy of this gem is in building richer messages. See Slack's
[Block Kit Builder](https://app.slack.com/block-kit-builder/) to understand
the structure of blocks better:

```ruby
SlackMessage.post_to('#general') do
  section do
    text "A job has generated some output for you to review."
    text 'And More' * 10
    link_button "See Results", "https://google.com"
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

* allow custom http_options in configuration
* allow custom slack username per built message
* so much error checking / handling

Contributing
------------

Contributions are very welcome. Fork, fix, submit pulls.

Contribution is expected to conform to the [Contributor Covenant](https://github.com/jmmastey/slack_message/blob/master/CODE_OF_CONDUCT.md).

License
------------

This software is released under the [MIT License](https://github.com/jmmastey/slack_message/blob/master/MIT-LICENSE).
