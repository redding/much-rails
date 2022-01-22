# frozen_string_literal: true

require "singleton"

module MuchRails; end

# MuchRails::RailsRoutes is a Singleton object that provides Rails' URL helpers
# and path/URL generation.
class MuchRails::RailsRoutes
  include Singleton
  include ::Rails.application.routes.url_helpers

  # These methods support stubbing #method_missing in tests but have no real
  # effect or behavior.

  def method_missing(name, *args, &block)
    super
  end

  def respond_to_missing?(*args)
    super
  end

  private

  def default_url_options
    ::Rails.application.routes.default_url_options
  end
end
