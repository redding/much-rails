# frozen_string_literal: true

require "much-rails/mixin"

module MuchRails; end

# MuchRails::CallMethod is a mix-in to implement the `call`
# class/instance method pattern.
module MuchRails::CallMethod
  include MuchRails::Mixin

  mixin_class_methods do
    def call(*args, &block)
      new(*args, &block).call
    end
  end

  mixin_instance_methods do
    def call
      on_call
    end

    def on_call
      raise NotImplementedError
    end
  end
end
