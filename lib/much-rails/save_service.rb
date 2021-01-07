# frozen_string_literal: true

require "active_record"
require "much-rails/mixin"
require "much-rails/result"
require "much-rails/service"

# MuchRails::SaveService is a common mix-in for all service objects that
# save (e.g. create/update) records.
module MuchRails::SaveService
  include MuchRails::Mixin

  mixin_included do
    include MuchRails::Service

    around_call do |receiver|
      receiver.call
    rescue ActiveRecord::RecordInvalid => ex
      set_the_return_value_for_the_call_method(
        MuchRails::Result.failure(
          record: ex.record,
          exception: ex,
          validation_errors: ex.record&.errors.to_h,
          validation_error_messages: ex.record&.errors&.full_messages.to_a))
    end
  end
end
