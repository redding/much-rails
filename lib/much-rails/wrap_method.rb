# frozen_string_literal: true

require "much-rails/config"
require "much-rails/mixin"

module MuchRails; end

# MuchRails::WrapMethod is a mix-in to implement the `wrap` class/instance
# method pattern used in service objects, etc.
module MuchRails::WrapMethod
  include MuchRails::Mixin

  mixin_included do
    include MuchRails::Config

    add_config :wrap_method
  end

  mixin_class_methods do
    def wrap(objects, *args)
      Array.wrap(objects).map do |object|
        public_send(wrap_initializer_method, object, *args)
      end
    end

    def wrap_with_index(objects, **kargs)
      Array.wrap(objects).each_with_index.map do |object, index|
        public_send(wrap_initializer_method, object, index: index, **kargs)
      end
    end

    def wrap_initializer_method(value = nil)
      wrap_method_config.wrap_initializer_method = value if value
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
