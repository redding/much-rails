# frozen_string_literal: true

module MuchRails
  class Railtie < Rails::Railtie
    initializer "much-rails-gem" do |app|
      # Helpers
      ActionView::Base.include(MuchRails::Layout::Helper)

      require "much-rails/assets"
      MuchRails::Assets.configure_for_rails(::Rails)
      app.middleware.use MuchRails::Assets::Server

      # This should be `true` in development so things fail fast and give the
      # developers rich error information for debugging purposes.
      #
      # This should be `false` in all other envs so proper HTTP response
      # statuses are returned.
      MuchRails::Action.raise_response_exceptions = Rails.env.development?

      # See https://github.com/ohler55/oj/blob/master/pages/Rails.md.
      Oj.optimize_rails

      MuchResult.default_transaction_receiver = ActiveRecord::Base
    end
  end
end
