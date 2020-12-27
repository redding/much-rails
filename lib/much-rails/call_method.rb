# frozen_string_literal: true

require "much-plugin"

# MuchRails::CallMethod is a mix-in to implement the `call`
# class/instance method pattern.
module MuchRails; end
module MuchRails::CallMethod
  include MuchPlugin

  plugin_class_methods do
    def call(*args, &block)
      new(*args, &block).call
    end
  end

  plugin_instance_methods do
    def call
      on_call
    end

    def on_call
      raise NotImplementedError
    end
  end
end
