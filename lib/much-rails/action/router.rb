# frozen_string_literal: true

require "much-rails/action/base_router"

module MuchRails; end
module MuchRails::Action; end

class MuchRails::Action::Router < MuchRails::Action::BaseRouter
  DEFAULT_CONTROLLER_NAME = "application"
  CONTROLLER_CALL_ACTION_METHOD_NAME = :much_rails_call_action
  CONTROLLER_NOT_FOUND_METHOD_NAME = :much_rails_not_found
  ACTION_CLASS_PARAM_NAME = :much_rails_action_class_name

  def self.url_class
    MuchRails::Action::Router::URL
  end

  def self.load(routes_file_name, controller_name: nil)
    if routes_file_name.to_s.strip.empty?
      raise(
        ArgumentError,
        "expected a routes file name, given `#{routes_file_name.inspect}`.",
      )
    end

    file_path = ::Rails.root.join("config/routes/#{routes_file_name}.rb")
    unless file_path.exist?
      raise ArgumentError, "routes file `#{file_path.inspect}` does not exist."
    end

    new(routes_file_name, controller_name: controller_name) do
      instance_eval(File.read(file_path), file_path.to_s, 1)
    end
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
    draw_url_to   = "#{controller_name}##{CONTROLLER_NOT_FOUND_METHOD_NAME}"
    draw_route_to = "#{controller_name}##{CONTROLLER_CALL_ACTION_METHOD_NAME}"

    definition_names = Set.new

    definitions.each do |definition|
      definition.request_type_actions.each do |request_type_action|
        application_routes_draw_scope.public_send(
          definition.http_method,
          definition.path,
          to: draw_route_to,
          as: (definition.name if definition_names.add?(definition.name)),
          defaults:
            definition.default_params.merge({
              ACTION_CLASS_PARAM_NAME => request_type_action.class_name,
              "format" => request_type_action.format,
            }),
          constraints: request_type_action.constraints_lambda,
        )
      end

      next unless definition.has_default_action_class_name?

      application_routes_draw_scope.public_send(
        definition.http_method,
        definition.path,
        to: draw_route_to,
        as: (definition.name if definition_names.add?(definition.name)),
        defaults:
          definition.default_params.merge({
            ACTION_CLASS_PARAM_NAME => definition.default_action_class_name,
            "format" => definition.default_action_format,
          }),
      )
    end

    # Draw each URL that doesn't have a route definition so that we can generate
    # them using MuchRails::RailsRoutes.
    unrouted_urls.each do |url|
      application_routes_draw_scope.get(url.path, to: draw_url_to, as: url.name)
    end
  end
  alias_method :draw, :apply_to

  class URL < MuchRails::Action::BaseRouter::BaseURL
    def path_for(**kargs)
      MuchRails::RailsRoutes.instance.public_send(
        "#{name}_path",
        **kargs.symbolize_keys.except(:format),
      )
    end

    def url_for(**kargs)
      MuchRails::RailsRoutes.instance.public_send(
        "#{name}_url",
        **kargs.symbolize_keys.except(:format),
      )
    end
  end
end
