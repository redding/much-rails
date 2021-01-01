# frozen_string_literal: true

require "active_record"
require "much-rails/action/head_result"
require "much-rails/action/redirect_to_result"
require "much-rails/action/render_result"
require "much-rails/action/router"
require "much-rails/action/send_data_result"
require "much-rails/action/send_file_result"
require "much-rails/action/unprocessable_entity_result"
require "much-rails/boolean"
require "much-rails/config"
require "much-rails/date"
require "much-rails/plugin"
require "much-rails/time"
require "much-rails/wrap_and_call_method"

# MuchRails::Action defines the common behaviors for all view action classes.
module MuchRails; end
module MuchRails::Action
  ForbiddenError = Class.new(StandardError)
  ActionError = Class.new(StandardError)

  include MuchRails::Plugin

  def self.sanitized_exception_classes
    [ActiveRecord::RecordInvalid]
  end

  def self.raise_response_exceptions=(value)
    @raise_response_exceptions = value
  end

  def self.raise_response_exceptions?
    !!@raise_response_exceptions
  end

  plugin_included do
    include MuchRails::Config
    include MuchRails::WrapAndCallMethod

    add_config :much_rails_action

    attr_reader :params, :errors
  end

  plugin_class_methods do
    def action_error_class
      MuchRails::Action::ActionError
    end

    def params_root(*args)
      much_rails_action_config.set_params_root(args) if args.any?
      much_rails_action_config.params_root
    end

    def required_params(*args)
      much_rails_action_config.add_required_params(args) if args.any?
      much_rails_action_config.required_params
    end

    def date_params(*args)
      much_rails_action_config.add_date_params(self, args) if args.any?
      much_rails_action_config.date_params
    end

    def time_params(*args)
      much_rails_action_config.add_time_params(self, args) if args.any?
      much_rails_action_config.time_params
    end

    def boolean_params(*args)
      much_rails_action_config.add_boolean_params(self, args) if args.any?
      much_rails_action_config.boolean_params
    end

    def format(*args)
      much_rails_action_config.set_format(args.first) if args.any?
      much_rails_action_config.format
    end

    def on_validation(&block)
      much_rails_action_config.add_on_validation_block(block)
      much_rails_action_config.on_validation_blocks
    end

    def on_validation_blocks
      much_rails_action_config.on_validation_blocks
    end

    def on_call(&block)
      much_rails_action_config.set_on_call_block(block)
      much_rails_action_config.on_call_block
    end

    def on_call_block
      much_rails_action_config.on_call_block
    end

    def on_before_call(&block)
      much_rails_action_config.add_on_before_call_block(block)
      much_rails_action_config.on_before_call_blocks
    end

    def on_before_call_blocks
      much_rails_action_config.on_before_call_blocks
    end

    def on_after_call(&block)
      much_rails_action_config.add_on_after_call_block(block)
      much_rails_action_config.on_after_call_blocks
    end

    def on_after_call_blocks
      much_rails_action_config.on_after_call_blocks
    end
  end

  plugin_instance_methods do
    def initialize(params:)
      @params = params.to_h.with_indifferent_access
      @errors = Hash.new { |hash, key| hash[key] = [] }
    end

    def on_call
      return @much_rails_action_result if @much_rails_action_result

      catch(:halt) do
        validate_action
        on_action_call if valid_action?
      end

      if valid_action? && successful_action?
        @much_rails_action_result ||= default_action_success_result
      else
        @much_rails_action_result = default_action_failure_result
      end
    end

    def valid_action?
      if @much_rails_valid_action.nil?
        @much_rails_valid_action = errors.compact.empty?
      end

      @much_rails_valid_action
    end

    def successful_action?
      if @much_rails_successful_action.nil?
        @much_rails_successful_action = errors.compact.empty?
      end

      @much_rails_successful_action
    end

    private

    def default_action_success_result
      MuchRails::Action::HeadResult.new(:ok)
    end

    def default_action_failure_result
      MuchRails::Action::UnprocessableEntityResult.new(errors)
    end

    def validate_action
      validate_action_required_params
      validate_action_date_params
      validate_action_time_params
      call_action_on_validation_blocks
    end

    def validate_action_required_params
      self.class.required_params.each do |param_name|
        if params[param_name].blank?
          add_required_param_error(param_name)
        end
      end
    end

    def validate_action_date_param(name)
      __send__(name.to_s)
    rescue MuchRails::Date::InvalidError
      errors[name] << action_date_param_error_message(name)
    end

    def validate_action_date_params
      self.class.date_params.each do |param|
        validate_action_date_param(param)
      end
    end

    def validate_action_time_param(name)
      __send__(name.to_s)
    rescue MuchRails::Time::InvalidError
      errors[name] << action_time_param_error_message(name)
    end

    def validate_action_time_params
      self.class.time_params.each do |param|
        validate_action_time_param(param)
      end
    end

    def call_action_on_validation_blocks
      self.class.on_validation_blocks.each do |on_validation_block|
        instance_eval(&on_validation_block)
      end
    end

    def action_required_param_error_message(param_name)
      "can't be blank"
    end

    def action_date_param_error_message(param_name)
      "invalid date"
    end

    def action_time_param_error_message(param_name)
      "invalid time"
    end

    def on_action_call
      call_action_on_before_call_blocks
      catch(:halt) { instance_exec(&self.class.on_call_block) }
      call_action_on_after_call_blocks
    rescue *MuchRails::Action.sanitized_exception_classes => ex
      raise(self.class.action_error_class, ex.message, ex.backtrace, cause: ex)
    end

    def call_action_on_before_call_blocks
      self.class.on_before_call_blocks.each do |on_before_call_block|
        instance_eval(&on_before_call_block)
      end
    end

    def call_action_on_after_call_blocks
      self.class.on_after_call_blocks.each do |on_after_call_block|
        instance_eval(&on_after_call_block)
      end
    end

    def add_required_param_error(param_name)
      errors[param_name] << action_required_param_error_message(param_name)
    end

    def halt
      throw(:halt)
    end

    def render(view_model = nil, **kargs)
      @much_rails_action_result =
        MuchRails::Action::RenderResult.new(view_model, **kargs)
      halt
    end

    def redirect_to(*args)
      @much_rails_action_result =
        MuchRails::Action::RedirectToResult.new(*args)
      halt
    end

    def head(*args)
      @much_rails_action_result =
        MuchRails::Action::HeadResult.new(*args)
      halt
    end

    def send_file(*args)
      @much_rails_action_result =
        MuchRails::Action::SendFileResult.new(*args)
      halt
    end

    def send_data(*args)
      @much_rails_action_result =
        MuchRails::Action::SendDataResult.new(*args)
      halt
    end
  end

  class MuchRailsActionConfig
    attr_reader :params_root, :required_params, :date_params, :time_params
    attr_reader :boolean_params, :format, :on_validation_blocks
    attr_reader :on_call_block, :on_before_call_blocks, :on_after_call_blocks

    def initialize
      @params_root = nil
      @required_params = []
      @date_params = []
      @time_params = []
      @boolean_params = []

      @format = nil

      @on_validation_blocks = []
      @on_before_call_blocks = []
      @on_after_call_blocks = []
      @on_call_block = -> {}
    end

    def set_params_root(value)
      @params_root = value
    end

    def add_required_params(param_names)
      @required_params.concat(Array.wrap(param_names))
    end

    def add_date_params(klass, param_names)
      Array.wrap(param_names).tap { |names|
        @date_params.concat(names)

        names.each do |name|
          klass.public_send(:define_method, name, &memoize_date_decode(name))
        end
      }
    end

    def add_time_params(klass, param_names)
      Array.wrap(param_names).tap { |names|
        @time_params.concat(names)

        names.each do |name|
          klass.public_send(:define_method, name, &memoize_time_decode(name))
        end
      }
    end

    def add_boolean_params(klass, param_names)
      Array.wrap(param_names).tap { |names|
        @boolean_params.concat(names)

        names.each do |name|
          klass.public_send(
            :define_method, "#{name}?", &memoize_boolean_decode(name))
        end
      }
    end

    def set_format(value)
      @format = value
    end

    def add_on_validation_block(block)
      @on_validation_blocks << block
    end

    def set_on_call_block(block)
      @on_call_block = block
    end

    def add_on_before_call_block(block)
      @on_before_call_blocks << block
    end

    def add_on_after_call_block(block)
      @on_after_call_blocks << block
    end

    private

    def memoize_date_decode(method_name)
      -> {
        instance_variable_name = "@#{method_name}"
        if instance_variable_get(instance_variable_name).nil?
          instance_variable_set(
            instance_variable_name,
            MuchRails::Date.for(params[method_name])
          )
        end
        instance_variable_get(instance_variable_name)
      }
    end

    def memoize_time_decode(method_name)
      -> {
        instance_variable_name = "@#{method_name}"
        if instance_variable_get(instance_variable_name).nil?
          instance_variable_set(
            instance_variable_name,
            MuchRails::Time.for(params[method_name])
          )
        end
        instance_variable_get(instance_variable_name)
      }
    end

    def memoize_boolean_decode(method_name)
      -> {
        instance_variable_name = "@#{method_name}"
        if instance_variable_get(instance_variable_name).nil?
          instance_variable_set(
            instance_variable_name,
            MuchRails::Boolean::convert(params[method_name])
          )
        end
        instance_variable_get(instance_variable_name)
      }
    end
  end
end
