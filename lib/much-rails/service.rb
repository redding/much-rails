# frozen_string_literal: true

require "much-rails/call_method_callbacks"
require "much-rails/mixin"
require "much-rails/wrap_and_call_method"

module MuchRails; end

# MuchRails::Service is a common mix-in for service objects. It supports
# the single `.call` method API with before/after callback support.
module MuchRails::Service
  include MuchRails::Mixin

  mixin_included do
    include MuchRails::CallMethodCallbacks
    include MuchRails::WrapAndCallMethod
  end
end
