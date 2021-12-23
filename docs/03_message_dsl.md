## The Message DSL

A pretty good number of the elements available in BlockKit are usable in SlackMessage. There are also a few elements that haven't been implemented in the official API, but are too useful to be missing.

### Basic Text

While BlockKit officially requires that any elements are contained within a section element, that requirement is relaxed in SlackMessage. If you don't specify a section, one will silently be created to encapsulate your code. That's the secret behind the most basic messages in these docs.

```ruby
SlackMessage.build do
  text "couldn't be easier"
end

# => [{:type=>"section",
#  :text=>{:type=>"mrkdwn", :text=>"couldn't be easier"}
# }]
```

This is equivalent to the more verbose version with a declared section.

```ruby
SlackMessage.build do
  section do
    text "could be easier"
  end
end

# => [{:type=>"section",
#  :text=>{:type=>"mrkdwn", :text=>"could be easier"}
# }]
```

Text elements are the most basic type of element. Adding multiple text calls
will add a newline between text calls, which will cause a line break
appropriately.

```ruby
SlackMessage.build do
  text "one fish, two fish"
  text "red fish, blue fish"
end

# => [{:type=>"section",
#  :text=>{:type=>"mrkdwn", :text=>"one fish, two fish\nred fish, blue fish"}
# }]
```

Slack uses a [faux-markdown syntax called
mrkdwn](https://api.slack.com/reference/surfaces/formatting#basics), which you
may be familiar with by typing in the Slack app itself. The API will
automatically render mrkdwn appropriately.

```ruby
SlackMessage.build do
  text "*Favorite Colors*"
  text "_John_: ~red~ actually blue."
end

# => [{:type=>"section",
# :text=>{:type=>"mrkdwn", :text=>"*Favorite Colors*\n_John_: ~red~ actually blue."}}]
```

Rendering emoji in messages is possible using either a) real unicode emoji in
your message, or b) using the `:emojiname:` syntax, which supports any emoji
that would work in your Slack app itself, including custom emoji.

```ruby
SlackMessage.build do
  text ":shipit_squirrel:🚀 time to gooo :tada:"
end

# => [{:type=>"section",
#   :text=>{:type=>"mrkdwn", :text=>":shipit_squirrel:🚀 time to gooo :tada:"}
# }]
```

To add a link using Slack's non-markdown link syntax, use the `link` helper
method interpolated into a text element. Using the `link` helper as its own
element won't work, as the method simply returns a string that has to be
included into a text element specifically.

```ruby
SlackMessage.build do
  text "Your #{link('build', 'https://google.com')} is ready."
end

# => [{:type=>"section",
#  :text=>{:type=>"mrkdwn", :text=>"Your <https://google.com|build> is ready."}
# }]
```

While the API squishes whitespace (much in the same way HTML does), it may
sometimes be useful to add a blank line between text _without_ adding a new
section to your message. To do so, use the pseudo-element `blank_line`.

```ruby
SlackMessage.build do
  text "don't let this line"
  blank_line
  text "touch this line."
end

# => => [{:type=>"section",
#  :text=>{:type=>"mrkdwn", :text=>"don't let this line\n \ntouch this line."}
# }]
```

Note that between the two newlines in the above example is a unicode emspace,
which the API will respect as a line worth rendering.

### Buttons

BlockKit allows you to specify a button to the right of a section / block. That
button will be aligned outside the normal space for a section, and is meant to
link out of the app. To create one of these, use the `link_button` helper.

```ruby
SlackMessage.build do
  text "Your daily stats are ready @here"
  link_button "Stats Dashboard", stats_dashboard_url
end

# => [{:type=>"section",
# :text=>{:type=>"mrkdwn", :text=>"Your daily stats are ready @here"},
# :accessory=>
#  {:type=>"button",
#   :url=>"http://yoursite.com/stats_dashboard",
#   :text=>{:type=>"plain_text", :text=>"Stats Dashboard", :emoji=>true},
#   :style=>:primary}}]
```

Slack allows three styles for buttons: `default`, `primary`, and `danger`.
These correspond to gray, green and red buttons respectively. If not specified,
SlackMessage will use the `primary` style for buttons. I get that this could be
confusing when there is a default style, but in my experience, a colorful button
is way more common.

You can override the button style by specifying the style with your link button.

```ruby
SlackMessage.build do
  text "A job has failed catastrophically!"
  link_button "Sidekiq Dashboard", sidekiq_dashboard_url, style: :danger
end

# => [{:type=>"section",
# :text=>{:type=>"mrkdwn", :text=>"A job has failed catastrophically!"},
# :accessory=>
#  {:type=>"button",
#   :url=>"https://yoursite.com/sidekiq",
#   :text=>{:type=>"plain_text", :text=>"Sidekiq Dashboard", :emoji=>true},
#   :style=>:danger}}]
```

### Ordered and Unordered Lists

The Slack API doesn't have native support for HTML-style ordered and unordered
lists, but there are convenience methods in SlackMessage to render a close
approximation.

```ruby
SlackMessage.build do
  section do
    text '*Pet Goodness Tiers*'

    ol([
      'tiny pigs',
      'reptiles',
      'dogs',
      'cats',
    ])
  end

  section do
    text '_voted by_'
    ul(['Joe', 'Emily', 'Sophia', 'Matt'])
  end
end
```

Because Slack automatically collapses leading whitespace, indention of lists is
handled using unicode emspaces. Bullets for unordered lists are also unicode
characters to avoid being read as markdown.

### List Items (e.g. HTML dt & dd)

When trying to represent title / value lists, you can use the "list item" block
type to pass a set of values. Slack does not allow you to customize how many
items are shown per line, so you'll just have to work with it.

```ruby
SlackMessage.build do
  text 'Import results are available!'

  list_item 'Import Date', Date.today.to_s
  list_item 'Items Imported', 55_000
  list_item 'Errors', 23
  list_item 'Bad Values', errors.map(&:to_s)
end
```

### Including Multiple Sections

Adding more sections is trivial. Simply declare each section and it will be
separated in the rendered message. This can often occur when looping.

```ruby
SlackMessage.build do
  pet_types.each do |type, breeds|
    section do
      text "*#{type}:* #{breeds.join(", ")}"
    end
  end
end
```

It can also be useful to add a visual divider (similar to a `hr` in HTML)
between sections. To add one of these, use the `divider` helper. You can also
add a divider at the end of all the sections, but it often looks silly.

```ruby
SlackMessage.build do
  section do
    text "*Topsiders:* Emily, Elsie, Derick"
  end

  divider

  section do
    text "*Undergrounders:* Kristina, Lauren, Different Emily"
  end
end

# => [
#  {:type=>"section", :text=>{:type=>"mrkdwn", :text=>"*Topsiders:* Emily, Elsie, Derick"}},
#  {:type=>"divider"},
#  {:type=>"section", :text=>{:type=>"mrkdwn", :text=>"*Undergrounders:* Kristina, Lauren, Different Emily"}}
# ]
```

Note that a divider can only occur between sections, not within a single
section. Because of how implicit sections are built, it may look like this works
for simple messages. You may have troubles when you start adding more
complicated elements to your messages.

### Images
TODO: image, accessory_image

### Footers (Context)

Slack allows you to add a small additional piece of text to your message, which
will be rendered in italics and small text. It can support both links and emoji,
and is useful for providing minor details for your message.

```ruby
SlackMessage.build do
  text "New coffee complaints have been added."
  context "this complaint added by #{link('Joe Mastey', 'hello@joemastey.com')}."
end

# => [{:type=>"section",
#      :text=>{:type=>"mrkdwn", :text=>"New coffee complaints have been added."}
#     },
#     {:type=>"context", :elements=>
#       [{:type=>"mrkdwn",
#         :text=>"this complaint added by <hello@joemastey.com|Joe Mastey>."
#     }]
# }]
```

Context does not belong to a section, and is per-message, not per-section.
Specifying more than one context will simply overwrite previous calls.

### Bot Customization

By default - and with scheduled messages - Slack will use the name and icon of
the Slack app whose API key you configured. As seen before, it's
possible to override those default names and icons in configuration. However, it
can also be customized per-message.

```ruby
SlackMessage.build do
  bot_icon ":sad_robot:"
  bot_name "BadNewsBuildBot"

  text "The build is broken. @here"
end

# => [{:type=>"section", :text=>{:type=>"mrkdwn", :text=>"The build is broken. @here"}}]
```

Notice that the bot details aren't shown in the output of the `build` command.
To view the changes these methods cause, use `debug` mode.

The `bot_icon` can be specified as either an emoji (`:example:`), or a URL
pointing to an image (`http://mysite.com/shipit.png`). Any other value seems to
cause an error.

### Custom Notification Text

For users who have notifications turned on, Slack will provide a small message
preview when you send them a message. By default, this preview will take the
first several words from your message.

However, you can specify some custom notification text to be shown to the user.
This text supports basic emoji and formatting, but nothing complicated.

```ruby
SlackMessage.build do
  notification_text "Having issues with the build. :ohnoes:"

  text "The build is broken. The error message was 'undefined method round for NilClass'"

# => [{:type=>"section",
# :text=>
#  {:type=>"mrkdwn",
#   :text=>"The build is broken. The error message was 'undefined method round for NilClass'"}}]
end
```

Again notice that notification text is not set within the blocks themselves, so
you will need to enable debugging to see how it changes what is sent to the API.

---

Next: [Editing Messages](https://jmmastey.github.io/slack_message/04_editing_messages)
