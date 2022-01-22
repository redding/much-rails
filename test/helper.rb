# frozen_string_literal: true

# this file is automatically required when you run `assert`
# put any test helpers here

# add the root dir to the load path
$LOAD_PATH.unshift(File.expand_path("..", __dir__))
TEST_SUPPORT_PATH = File.expand_path("support", __dir__)

# require pry for debugging (`binding.pry`)
require "pry"

require "test/support/factory"

ENV["RAILS_ENV"] ||= "test"

require "rails"

module TestRails
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    config.eager_load = false
  end
end

# Initialize the Rails application.
Rails.application.initialize!
