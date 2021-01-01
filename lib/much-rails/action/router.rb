# frozen_string_literal: true

require "much-rails/action/base_router"
require "much-rails/rails_routes"

module MuchRails; end
module MuchRails::Action; end

class MuchRails::Action::Router < MuchRails::Action::BaseRouter
  DEFAULT_CONTROLLER_NAME = "application"
  CONTROLLER_METHOD_NAME = :much_rails_call_action
  ACTION_CLASS_PARAM_NAME = :much_rails_action_class_name

  def self.url_class
    MuchRails::Action::Router::URL
  end

  class URL < MuchRails::Action::BaseRouter::BaseURL
    def path_for(*args)
      MuchRails::RailsRoutes.public_send("#{name}_path", *args)
    end

    def url_for(*args)
      MuchRails::RailsRoutes.public_send("#{name}_url", *args)
    end
  end
end
