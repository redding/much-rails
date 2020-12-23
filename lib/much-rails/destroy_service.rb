# frozen_string_literal: true

require "much-plugin"
require "much-rails/records"
require "much-rails/records/validate_destroy"
require "much-rails/service"
require "much-result"

# MuchRails::DestroyService is a common mix-in for all service objects that
# destroy records.
module MuchRails::DestroyService
  include MuchPlugin

  plugin_included do
    include MuchRails::Service

    around_call do |receiver|
      receiver.call
    rescue MuchRails::Records::ValidateDestroy::DestructionInvalid => ex
      set_the_return_value_for_the_call_method(
        MuchResult.failure(
          exception: ex,
          validation_errors: ex&.destruction_errors.to_h))
    end
  end
end
