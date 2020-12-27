# frozen_string_literal: true

require "active_record"
require "much-plugin"
require "much-rails/service"
require "much-result"

# MuchRails::SaveService is a common mix-in for all service objects that
# save (e.g. create/update) records.
module MuchRails::SaveService
  include MuchPlugin

  plugin_included do
    include MuchRails::Service

    around_call do |receiver|
      receiver.call
    rescue ActiveRecord::RecordInvalid => ex
      set_the_return_value_for_the_call_method(
        MuchResult.failure(
          record: ex.record,
          exception: ex,
          validation_errors: ex.record&.errors.to_h,
          validation_error_messages: ex.record&.errors&.full_messages.to_a))
    end
  end
end
