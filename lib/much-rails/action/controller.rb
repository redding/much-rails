# frozen_string_literal: true

require "much-rails/action/router"
require "much-rails/mixin"

module MuchRails; end
module MuchRails::Action; end

# MuchRails::Action::Controller defines the behaviors for controllers processing
# MuchRails::Actions.
module MuchRails::Action::Controller
  include MuchRails::Mixin

  mixin_included do
    attr_reader :much_rails_action_class

    before_action(
      :require_much_rails_action_class,
      only: MuchRails::Action::Router::CONTROLLER_CALL_ACTION_METHOD_NAME
    )
    before_action :permit_all_much_rails_action_params
  end

  mixin_instance_methods do
    define_method(
      MuchRails::Action::Router::CONTROLLER_CALL_ACTION_METHOD_NAME,
    ) do
      respond_to do |format|
        format.public_send(much_rails_action_class.format) do
          result =
            much_rails_action_class.call(
              params: much_rails_action_params,
              current_user: current_user,
              request: request,
            )
          instance_exec(result, &result.execute_block)
        end
      end
    end

    define_method(
      MuchRails::Action::Router::CONTROLLER_NOT_FOUND_METHOD_NAME,
    ) do
      respond_to do |format|
        format.html do
          head :not_found
        end
      end
    end

    def much_rails_action_class_name
      "::#{params[MuchRails::Action::Router::ACTION_CLASS_PARAM_NAME]}"
    end

    def much_rails_action_params
      # If a `params_root` value is specified, pull the params from that key and
      # merge them into the base params.
      Array
        .wrap(much_rails_action_class&.params_root)
        .reduce(
          params
            .to_h
            .except(
              MuchRails::Action::Router::ACTION_CLASS_PARAM_NAME,
              :controller,
              :action,
            ),
        ) do |acc, root|
          acc.merge(acc[root].to_h)
        end
    end

    def require_much_rails_action_class
      begin
        @much_rails_action_class = much_rails_action_class_name.constantize
      rescue NameError => ex
        if MuchRails.config.action.raise_response_exceptions?
          raise(
            MuchRails::Action::ActionError,
            "No Action class defined for "\
            "#{much_rails_action_class_name.inspect}.",
            cause: ex,
          )
        else
          head(:not_found)
        end
      end
    end

    def permit_all_much_rails_action_params
      params.permit!
    end
  end
end
