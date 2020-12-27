# frozen_string_literal: true

require "much-plugin"
require "much-rails/call_method"
require "much-rails/wrap_method"
require "much-result"

# MuchRails::WrapAndCallMethod is a mix-in to implement the `wrap_and_call`
# and `wrap_and_map_call` class/instance method pattern.
module MuchRails; end
module MuchRails::WrapAndCallMethod
  include MuchPlugin

  plugin_included do
    include MuchRails::CallMethod
    include MuchRails::WrapMethod
  end

  plugin_class_methods do
    def wrap_and_call(objects, *args)
      wrap(objects, *args).each(&:call)
    end

    def wrap_and_map_call(objects, *args)
      wrap(objects, *args).map(&:call)
    end

    def wrap_and_capture_call(objects, *args, capturing_result:, **kargs)
      capturing_result.capture_for_all(
        wrap_and_map_call(objects, *args, **kargs))
    end

    def wrap_and_capture_call!(objects, *args, capturing_result:, **kargs)
      capturing_result.capture_for_all!(
        wrap_and_map_call(objects, *args, **kargs))
    end
  end
end
