# frozen_string_literal: true

module MuchRails
  class Railtie < Rails::Railtie
    initializer "much-rails-gem" do |app|
      # Helpers
      ActionView::Base.include(MuchRails::Layout::Helper)

      require "much-rails/assets"
      MuchRails::Assets.configure_for_rails(::Rails)
      app.middleware.use MuchRails::Assets::Server
    end
  end
end
