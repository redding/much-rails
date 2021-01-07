# frozen_string_literal: true

require "much-rails/call_method"
require "much-rails/config"
require "much-rails/mixin"

module MuchRails; end

# MuchRails::CallMethodCallbacks is a common mix-in for adding before/after
# callback support to MuchRails::CallMethod. This is separate from the
# MuchRails::CallMethod mix-in as it adds a bit of overhead (e.g. the
# `much_rails_call_callbacks_config`) that may not be desired by things
# just wanting to use the basic `MuchRails::CallMethod`. This allows opting-in
# to callback support as needed.
module MuchRails::CallMethodCallbacks
  include MuchRails::Mixin

  mixin_included do
    include MuchRails::CallMethod
    include MuchRails::Config

    add_config :much_rails_call_callbacks
  end

  mixin_class_methods do
    def before_call(&block)
      much_rails_call_callbacks_config.before_callbacks.append(block) if block
    end

    def prepend_before_call(&block)
      much_rails_call_callbacks_config.before_callbacks.prepend(block) if block
    end

    def after_call(&block)
      much_rails_call_callbacks_config.after_callbacks.append(block) if block
    end

    def prepend_after_call(&block)
      much_rails_call_callbacks_config.after_callbacks.prepend(block) if block
    end

    def around_call(&block)
      much_rails_call_callbacks_config.around_callbacks.append(block) if block
    end

    def prepend_around_call(&block)
      much_rails_call_callbacks_config.around_callbacks.prepend(block) if block
    end
  end

  mixin_instance_methods do
    def call
      set_the_return_value_for_the_call_method(nil)

      execute_before_callbacks
      execute_around_callbacks do
        set_the_return_value_for_the_call_method(on_call)
      end
      execute_after_callbacks

      the_return_value_for_the_call_method
    end

    # Do nothing by default - override as needed. Prefer this approach over
    # e.g. `raise NotImplementedError` as it allows any callbacks that have been
    # attached to run even if the actual `on_call` method was never overridden.
    def on_call
    end

    def set_the_return_value_for_the_call_method(value)
      @the_return_value_for_the_call_method = value
    end

    def the_return_value_for_the_call_method
      @the_return_value_for_the_call_method
    end

    private

    def execute_before_callbacks
      self
        .class
        .much_rails_call_callbacks_config
        .before_callbacks
        .each do |callback|
          instance_exec(&callback)
        end
    end

    def execute_around_callbacks(&on_call_block)
      self
        .class
        .much_rails_call_callbacks_config
        .around_callbacks
        .reverse
        .reduce(on_call_block){ |acc_proc, callback_proc|
          ->{ instance_exec(acc_proc, &callback_proc) }
        }
        .call
    end

    def execute_after_callbacks
      self
        .class
        .much_rails_call_callbacks_config
        .after_callbacks
        .each do |callback|
          instance_exec(&callback)
        end
    end
  end

  class MuchRailsCallCallbacksConfig
    attr_accessor :before_callbacks, :after_callbacks, :around_callbacks

    def initialize
      @before_callbacks = []
      @after_callbacks = []
      @around_callbacks = []
    end
  end
end
