# frozen_string_literal: true

require "much-rails/action/base_router"

module MuchRails; end
module MuchRails::Action; end

class MuchRails::Action::Router < MuchRails::Action::BaseRouter
  DEFAULT_CONTROLLER_NAME = "application"
  CONTROLLER_METHOD_NAME = :much_rails_call_action
  ACTION_CLASS_PARAM_NAME = :much_rails_action_class_name

  def self.url_class
    MuchRails::Action::Router::URL
  end

  def self.load(routes_file_name, controller_name: nil)
    if routes_file_name.to_s.strip.empty?
      raise(
        ArgumentError,
        "expected a routes file name, given `#{routes_file_name.inspect}`."
      )
    end

    file_path = ::Rails.root.join("config/routes/#{routes_file_name}.rb")
    unless file_path.exist?
      raise ArgumentError, "routes file `#{file_path.inspect}` does not exist."
    end

    new(routes_file_name, controller_name: controller_name) {
      instance_eval(File.read(file_path), file_path.to_s, 1)
    }
  end

  attr_reader :controller_name

  def initialize(name = nil, controller_name: nil, &block)
    super(name, &block)

    @controller_name = controller_name || DEFAULT_CONTROLLER_NAME
  end

  # Example:
  #   MyRouter = MuchRails::Action::Router.new { ... }
  #   Rails.application.routes.draw do
  #     root "/"
  #     MyRouter.draw(self)
  #   end
  def apply_to(application_routes_draw_scope)
    validate!
    draw_route_to = "#{controller_name}##{CONTROLLER_METHOD_NAME}"

    definitions.each do |definition|
      definition.request_type_actions.each do |request_type_action|
        application_routes_draw_scope.public_send(
          definition.http_method,
          definition.path,
          to: draw_route_to,
          as: definition.name,
          defaults:
            definition.default_params.merge({
              ACTION_CLASS_PARAM_NAME => request_type_action.class_name
            }),
          constraints: request_type_action.constraints_lambda,
        )
      end

      if definition.has_default_action_class_name?
        application_routes_draw_scope.public_send(
          definition.http_method,
          definition.path,
          to: draw_route_to,
          as: definition.name,
          defaults:
            definition.default_params.merge({
              ACTION_CLASS_PARAM_NAME => definition.default_action_class_name
            }),
        )
      end
    end
  end
  alias_method :draw, :apply_to

  class URL < MuchRails::Action::BaseRouter::BaseURL
    def path_for(*args)
      MuchRails::RailsRoutes.instance.public_send("#{name}_path", *args)
    end

    def url_for(*args)
      MuchRails::RailsRoutes.instance.public_send("#{name}_url", *args)
    end
  end
end
