# Changelog

## [2.2.1] - 2021-11-20
- Trying to fetch user ID for a string that isn't email-like raises an error.
- In tests, fetching user IDs is mocked out to prevent network requests.
- Tightened up and clarified README.
- Some internal cleanup and restructuring of modules.

## [2.2.0] - 2021-11-20
- When sending text, it is now possible to mention users and have their user
  IDs automatically converted using `<email@email.com>` within text nodes.
- It's now possible to override notification text.
- Errors received from the Slack API now raise `SlackMessage::ApiError`.
- Re-exposed a top-level method for getting user IDs, `SlackMessage.user_id`.
- Raising some better errors when no message payload is present.
- Using `build` now requires a profile, so configuration must exist.

## [2.1.0] - 2021-11-01
- Change to use Slack Apps for all profiles. This should allow growth toward
  updating messages, working with interactive messages etc.
- As a result, allow custom icons per profile / message.
- When sending a message, the first `text` block is used for the notification
  content. Should resolve "this content cannot be displayed".
- Significant restructuring of README.

## [2.0.0] - 2021-11-01
- Yeah that was all broken.

## [1.9.0] - 2021-10-27
- Add many validations so that trying to add e.g. empty text won't succeed.
  Previously that would be accepted but return `invalid_blocks` from the API.

## [1.8.1] - 2021-10-08
- Cleaned that rspec code a bit, added more matchers for real world use.

## [1.8.0] - 2021-10-07
- Added the ability to test in RSpec.

## [1.7.1] - 2021-10-06
- Fixed literally a syntax issue.
- Fixed specs.
- Fixed API to include JSON since consumers may not have loaded it.

## [1.7.0] - 2021-10-06
- THIS RELEASE IS BADLY BROKEN.
- Added new error messages when API configuration is wrong / missing.
- Fixed issue with `instance_eval` and using methods within block.
- Fixed issue with sectionless `list_item`.

## [1.6.0] - 2021-10-04
- Added `:default_channel` and `post_as` to deal with repetitive channel usage.

## [1.5.0] - 2021-10-01
- Added `ol` and `ul` to sections w/ some formatting.

## [1.4.0] - 2021-09-27
- Changed `image` to `accessory_image` to differentiate between the image block
  and the accessory image within a block.

## [1.3.0] - 2021-09-27
- Added ability to use custom names when posting.
- Added ability to post images within sections.
- Added warnings for potentially invalid URLs.

## [1.2.0] - 2021-09-26
- Fixed gemspec, which was entirely broken.

## [1.1.0] - 2021-09-26
- Expanded the README significantly w/ usage instructions.
- Added lots of error handling to requests.

## [1.0.0] - 2021-09-25
- Added the base gem w/ a DSL for constructing blocks using sections.
- Added a changelog, apparently.
