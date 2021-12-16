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

#### Posting

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

  text ":rocketship: <hello@joemastey.com>"

  context ":custom_slack_emoji: An example footer *with some markdown*."
end
```

### The Docs

#### Opinionated Stances

This gem is intended to stay simple. Other Slack gems have lots of config
options and abilities, which makes them powerful, but makes them a pain to use.

Accordingly, SlackMessage is developed with some strong opinions in mind:

* SlackMessage has no dependencies. Your lockfile is enough of a mess already.
* The code to build a message should look a lot like the message itself. Code
  that is simple to read and understand is a priority.
* Webhooks are passé. Only Slack Apps are supported now.
* Unless you request otherwise, text is always rendered using `mrkdwn`. If you
  want plaintext, you'll need to ask for it. Same for the `emoji` flag.
* As many API semantics as possible are hidden. For instance, if you post to
  something that looks like an email address, `slack_message` is going to try
  to look it up as an email address.
* A few little hacks on the block syntax, such as adding a `blank_line` (which
  doesn't exist in the API), or leading spaces.
* Configuration is kept as simple as possible. But, as much heavy lifting as
  possible should occur just once via configuration and not on every call.

Some behaviors that are still planned but not yet added:

* any interactive elements at all: https://api.slack.com/interactivity/handling
* multiple recipients: https://api.slack.com/methods/conversations.open
* more interesting return types for your message
* richer text formatting (for instance, `ul` is currently a hack)
* more mrkdwn syntax, like quotes or code blocks
* more and better organized testing capability
* posting ephemeral messages: https://api.slack.com/methods/chat.postEphemeral
* figure out the interplay of editing messages and notifications.
* some Rspec test harness for scheduled messages, editing, deleting (probably going to need a test overhaul)

Contributing
------------

Contributions are very welcome. Fork, fix, submit pull. Since simplicity of API is a strong priority, so opening an issue to discuss possible interface changes would be wise.

Contribution is expected to conform to the [Contributor Covenant](https://github.com/jmmastey/slack_message/blob/master/CODE_OF_CONDUCT.md).

License
------------

This software is released under the [MIT License](https://github.com/jmmastey/slack_message/blob/master/MIT-LICENSE).
