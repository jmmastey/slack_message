* [Configuration](https://jmmastey.github.io/slack_message/01_configuration)
* [Posting a Message](https://jmmastey.github.io/slack_message/02_posting_a_message)
* [The SlackMessage DSL](https://jmmastey.github.io/slack_message/03_message_dsl)
* [Editing Messages](https://jmmastey.github.io/slack_message/04_editing_messages)
* [Deleting Messages](https://jmmastey.github.io/slack_message/05_deleting_messages)
* [Mentions / Notifying Users](https://jmmastey.github.io/slack_message/06_notifying_users)
* [Testing](https://jmmastey.github.io/slack_message/07_testing)

SlackMessage is a gem that makes it easy to send messages to Slack from your
application. _Really_ easy.

```ruby
SlackMessage.post_to('#general') do
  text "We did it @here! :thumbsup:"
end
```

And not just simple messages. You can compose complicated messages quickly in a
DSL that's focused on usability and maintainability. It can be tough to
maintain code in other similar gems, but not here.

```ruby
SlackMessage.post_to('hello@joemastey.com') do
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

  context "Kicked off by <hello@joemastey.com> at **9:05am**"
end
```

It has no dependencies and minimal configuration needs, so you can get up and
running quickly.
