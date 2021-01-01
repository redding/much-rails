# frozen_string_literal: true

require "singleton"

# MuchRails::RailsRoutes is a Singleton object that provides Rails' URL helpers
# and path/URL generation.
module MuchRails; end
class MuchRails::RailsRoutes
  include Singleton
  include ::Rails.application.routes.url_helpers

  # These methods support stubbing #method_missing in tests but have no real
  # effect or behavior.

  def self.method_missing(name, *args, &block)
    super
  end

  def self.respond_to_missing?(*args)
    super
  end

  private

  def default_url_options
    ::Rails.application.config.action_mailer.default_url_options
  end
end
