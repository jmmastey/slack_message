Gem::Specification.new do |gem|
  gem.name        = 'slack_message'
  gem.version     = "1.0.0"
  gem.summary     = "A nice DSL for composing rich messages in Slack"
  gem.authors     = ["Joe Mastey"]
  gem.email       = 'hello@joemastey.com'
  gem.homepage    = 'https://rubygemgem.org/gems/slack_message'
  gem.licenses    = 'MIT'

  glob = lambda { |patterns| gem.files & Dir[*patterns] }

  gem.files       = ["lib/slack_message.rb"]
  gem.test_files  = glob['{spec/{**/}*_spec.rb']

  gem.metadata    = {
    "homepage_uri"    => "http://github.com/jmmastey/slack_message",
    "changelog_uri"   => "https://github.com/jmmastey/slack_message/blob/master/CHANGELOG.md",
    "source_code_uri" => "http://github.com/jmmastey/slack_message",
  }

  gem.add_development_dependency "rspec", "3.10.0"
  gem.add_development_dependency "pry", "0.14.1"
  gem.add_development_dependency "rb-readline", "0.5.5"
end
