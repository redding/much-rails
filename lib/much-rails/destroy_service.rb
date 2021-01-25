# frozen_string_literal: true

require "much-rails/mixin"
require "much-rails/records"
require "much-rails/records/validate_destroy"
require "much-rails/result"
require "much-rails/service"

module MuchRails; end

# MuchRails::DestroyService is a common mix-in for all service objects that
# destroy records.
module MuchRails::DestroyService
  include MuchRails::Mixin

  mixin_included do
    include MuchRails::Service

    around_call do |receiver|
      receiver.call
    rescue MuchRails::Records::DestructionInvalid => ex
      set_the_return_value_for_the_call_method(
        MuchRails::Result.failure(
          exception: ex,
          validation_errors: ex&.destruction_errors.to_h,
        ),
      )
    end
  end
end
