# Changelog

## [3.4.0] - 2023-02-21
- Add full support for ruby 3.0.x kwargs

## [3.3.0] - 2022-07-21
- Differentiate errors for bad JSON versus invalid block data.
- Expand tests to cover many more cases.
- Add validation for block size limit in Slack API.
- Add CI check to prevent checkin of `fit`, `fcontext` etc.

## [3.2.0] - 2022-06-23
- Fix bugs introduced by accidental checkin of incomplete refactor.

## [3.1.0] - 2022-04-18
- Methods from the calling context can now be called within a section block.

## [3.0.2] - 2022-04-16
- Fix tests on ruby 3.0.
- More adjustments and additions to docs.
- Add warnings when overriding notification text and context block.

## [3.0.1] - 2021-12-22
- Major overhaul of error handling and expansion on which errors trigger
  friendly messages for users.
- More additions to the docs, and working github pages integration.
- It's my birthday!

## [3.0.0] - 2021-12-19
- Return a more structured object from successful message sends.
- Add the ability to edit or delete a message.
- Complete overhaul of docs because they were too large.

## [2.4.0] - 2021-12-13
- Add ability to schedule messages, plus some guard rails around that.
- Add ability to debug by logging out the total set of params sent to the API.

## [2.3.1] - 2021-11-30
- Adjust that minimum version by changing some syntax to older styles. Given
  support for ruby 2.4 ended almost 2 years ago, going to go ahead and leave
  it behind.
- Remove lockfile from repo

## [2.3.0] - 2021-11-30
- Formally require minimum version of ruby. It wouldn't have worked anyway,
  but worth actually specifying.

## [2.2.2] - 2021-11-30
- Add github workflow for automatic CI runs. Stolen from another project.

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
