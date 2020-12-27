# frozen_string_literal: true

require "much-result"

# MuchRails::ChangeActionResult is a Result object intended to wrap and
# compose a MuchResult.
module MuchRails; end
class MuchRails::ChangeActionResult
  def self.success(**kargs)
    new(MuchResult.success(**kargs))
  end

  def self.failure(**kargs)
    new(MuchResult.failure(**kargs))
  end

  attr_reader :service_result

  def initialize(save_service_result)
    unless save_service_result.is_a?(MuchResult)
      raise(
        TypeError,
        "MuchResult expected, got #{save_service_result.class}")
    end

    @service_result = save_service_result

    @service_result.validation_errors ||= {}
  end

  def validation_errors
    @validation_errors ||=
      service_result.get_for_all_results(:validation_errors).to_h
  end

  def validation_error_messages
    validation_errors.values.flatten.compact
  end

  def extract_validation_error(field_name)
    validation_errors.delete(field_name)
  end

  def any_unextracted_validation_errors?
    !!(failure? && validation_errors.any?)
  end

  private

  def method_missing(name, *args, &block)
    service_result&.__send__(name, *args, &block)
  end

  def respond_to_missing?(*args)
    service_result.respond_to?(*args) || super
  end
end
