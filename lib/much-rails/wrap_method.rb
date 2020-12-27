# frozen_string_literal: true

require "much-plugin"
require "much-rails/config"

# MuchRails::WrapMethod is a mix-in to implement the `wrap` class/instance
# method pattern used in service objects, etc.
module MuchRails; end
module MuchRails::WrapMethod
  include MuchPlugin

  plugin_included do
    include MuchRails::Config

    add_config :wrap_method
  end

  plugin_class_methods do
    def wrap(objects, *args)
      Array.wrap(objects).map { |object|
        public_send(wrap_initializer_method, object, *args)
      }
    end

    def wrap_with_index(objects, **kargs)
      Array.wrap(objects).each_with_index.map { |object, index|
        public_send(wrap_initializer_method, object, index: index, **kargs)
      }
    end

    def wrap_initializer_method(value = nil)
      if value
        wrap_method_config.wrap_initializer_method = value
      end
      wrap_method_config.wrap_initializer_method
    end
  end

  class WrapMethodConfig
    attr_accessor :wrap_initializer_method

    def initialize
      @wrap_initializer_method = :new
    end
  end
end
