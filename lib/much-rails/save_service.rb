# frozen_string_literal: true

require "active_record"
require "much-rails/invalid_error"
require "much-rails/mixin"
require "much-rails/result"
require "much-rails/service"
require "much-rails/service_validation_errors"

module MuchRails; end

# MuchRails::SaveService is a common mix-in for all service objects that
# save (e.g. create/update) records.
module MuchRails::SaveService
  include MuchRails::Mixin

  mixin_included do
    include MuchRails::Service

    around_call do |receiver|
      receiver.call
    rescue *MuchRails::SaveService::ValidationErrors.exception_classes => ex
      set_the_return_value_for_the_call_method(
        MuchRails::SaveService::ValidationErrors.result_for(ex),
      )
    end
  end

  module ValidationErrors
    def self.add(exception_class, &block)
      service_validation_errors.add(exception_class, &block)
    end

    def self.exception_classes
      service_validation_errors.exception_classes
    end

    def self.result_for(ex)
      service_validation_errors.result_for(ex)
    end

    def self.service_validation_errors
      @service_validation_errors ||=
        MuchRails::ServiceValidationErrors
          .new
          .tap do |e|
            e.add(ActiveRecord::RecordInvalid) do |ex|
              MuchRails::SaveService::FailureResult.new(
                record: ex.record,
                exception: ex,
                validation_errors: ex.record&.errors.to_h,
                validation_error_messages:
                  ex.record&.errors&.full_messages.to_a,
              )
            end
            e.add(MuchRails::InvalidError) do |ex|
              MuchRails::SaveService::FailureResult.new(
                exception: ex,
                validation_errors: ex.errors,
                validation_error_messages: ex.error_messages,
              )
            end
          end
    end
  end

  module FailureResult
    def self.new(exception:, validation_errors:, **kargs)
      MuchResult.failure(
        exception: exception,
        validation_errors: validation_errors,
        **kargs,
      )
    end
  end
end
