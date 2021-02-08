# frozen_string_literal: true

require "much-rails/mixin"

# MuchRails::AbstractClass overrides the `new` class method to prevent a class
# from being instantiated directly.
module MuchRails::AbstractClass
  include MuchRails::Mixin

  after_mixin_included do
    self.abstract_class = self

    define_singleton_method(:new) do |*args, &block|
      if abstract_class?
        raise(
          NotImplementedError,
          "#{self} is an abstract class and cannot be instantiated.",
        )
      end

      super(*args, &block)
    end
  end

  mixin_class_methods do
    def abstract_class
      @abstract_class
    end

    def abstract_class=(value)
      @abstract_class = value
    end

    def abstract_class?
      !!(abstract_class == self)
    end
  end
end
