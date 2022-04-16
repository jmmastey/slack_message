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
 
### The Docs

You'll find much more information about how to use SlackMessage by visiting
[the docs](https://jmmastey.github.io/slack_message).
 

### A Rich DSL Focused on Maintainability

SlackMessage is able to build all kinds of rich messages for you. It focuses on
writing code that looks similar to the output messages themselves, with as
little repetition and cruft as possible.

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

### Opinionated Stances

This gem is intended to stay simple. Other Slack gems have lots of config
options and abilities, which makes them powerful, but makes them a pain to use.

Accordingly, SlackMessage is developed with some strong opinions in mind:

* SlackMessage has no dependencies. Your lockfile is enough of a mess already.
* A DSL that focuses on code that is easy to write, read, and maintain. Only
  features that can be implemented with that in mind are included.
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
* Configuration is kept simple, with helpers for frequently reused bots.

Some changes that are still planned or desired, but not yet added:

* any interactive elements at all: https://api.slack.com/interactivity/handling
* multiple recipients: https://api.slack.com/methods/conversations.open
* more mrkdwn syntax, like quotes or code blocks https://api.slack.com/reference/surfaces/formatting#line-breaks
* more and better organized testing capability (for scheduled messages, editing, deleting)
* posting ephemeral messages: https://api.slack.com/methods/chat.postEphemeral
* easier way to dump / load message responses
* updated docs w/ links to BlockBuilder

### Contributing

Contributions are very welcome. Fork, fix, submit pull. Since simplicity of API
is a strong priority, so opening an issue to discuss possible interface changes
would be wise.

Contribution is expected to conform to the [Contributor
Covenant](https://github.com/jmmastey/slack_message/blob/master/CODE_OF_CONDUCT.md).

### License

This software is released under the [MIT
License](https://github.com/jmmastey/slack_message/blob/master/MIT-LICENSE).
