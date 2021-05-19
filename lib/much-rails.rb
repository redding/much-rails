# frozen_string_literal: true

require "active_support"
require "active_support/core_ext"

require "much-rails/version"
require "much-rails/abstract_class"
require "much-rails/action"
require "much-rails/boolean"
require "much-rails/call_method"
require "much-rails/call_method_callbacks"
require "much-rails/change_action"
require "much-rails/change_action_result"
require "much-rails/config"
require "much-rails/date"
require "much-rails/decimal"
require "much-rails/destroy_action"
require "much-rails/destroy_service"
require "much-rails/has_slug"
require "much-rails/input_value"
require "much-rails/invalid_error"
require "much-rails/json"
require "much-rails/layout"
require "much-rails/not_given"
require "much-rails/mixin"
require "much-rails/records"
require "much-rails/result"
require "much-rails/save_action"
require "much-rails/save_service"
require "much-rails/service"
require "much-rails/time"
require "much-rails/view_models"
require "much-rails/wrap_and_call_method"
require "much-rails/wrap_method"

require "much-rails/railtie" if defined?(Rails::Railtie)

module MuchRails
  include MuchRails::Config
  include MuchRails::NotGiven

  add_config :much_rails, method_name: :config
  singleton_class.alias_method :configure, :configure_much_rails

  class MuchRailsConfig
    include MuchRails::Config

    add_instance_config :action, method_name: :action
    add_instance_config :layout, method_name: :layout

    def add_save_service_validation_error(exception_class, &block)
      MuchRails::SaveService::ValidationErrors.add(exception_class, &block)
    end

    def add_destroy_service_validation_error(exception_class, &block)
      MuchRails::DestroyService::ValidationErrors.add(exception_class, &block)
    end

    class ActionConfig
      attr_accessor :namespace
      attr_accessor :sanitized_exception_classes
      attr_accessor :raise_response_exceptions

      def initialize
        @namespace = ""
        @sanitized_exception_classes = [ActiveRecord::RecordInvalid]
        @raise_response_exceptions   = false
      end

      def raise_response_exceptions?
        !!@raise_response_exceptions
      end
    end

    class LayoutConfig
      attr_accessor :full_page_title_segment_separator
      attr_accessor :full_page_title_application_separator

      # Override as desired in an initializer, e.g.:
      #
      # Example:
      #   # in config/initializers/much_rails.rb
      #   MuchRails.config.layout.full_page_title_segment_separator " / "
      #   MuchRails.config.layout.full_page_title_application_separator " :: "
      def initialize
        @full_page_title_segment_separator = " - "
        @full_page_title_application_separator = " | "
      end
    end
  end
end
