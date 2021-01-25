# frozen_string_literal: true

require "active_model/error"
require "much-rails/mixin"

module MuchRails; end
module MuchRails::Records; end

# MuchRails::Records::ValidateDestroy is used to mix in custom validation
# logic and handling in destroying records.
#
# Include this module and define the #validate_destroy private method. Any
# calls to #destroy or #destroy! will first check if the record is
# #destroyable?. This check runs the custom #validate_destroy logic. If the
# record is not destroyable, the #validate_destroy method should add
# #destruction_error_messages.
module MuchRails::Records::ValidateDestroy
  include MuchRails::Mixin

  mixin_instance_methods do
    def destruction_error_messages
      @destruction_error_messages ||= []
    end

    def destroy(validate: true)
      return false if validate && !destroyable?

      super()
    end

    def destroy_without_validation
      destroy(validate: false)
    end

    def destroy!(as: :base, validate: true)
      if validate && !destroyable?
        raise MuchRails::Records::DestructionInvalid.new(self, field_name: as)
      end

      # `_raise_record_not_destroyed` is from ActiveRecord. This logic was
      # copied from Rails `destroy!` implementation.
      destroy(validate: validate) || _raise_record_not_destroyed
    end

    def destroy_without_validation!(as: :base)
      destroy!(as: as, validate: false)
    end

    def destroyable?
      destruction_error_messages.clear
      validate_destroy
      destruction_error_messages.none?
    end

    def not_destroyable?
      !destroyable?
    end

    private

    def validate_destroy
      raise NotImplementedError
    end
  end
end

class MuchRails::Records::DestructionInvalid < StandardError
  attr_reader :record, :errors, :error_full_messages

  def initialize(record = nil, field_name: :base)
    super(record&.destruction_error_messages.to_a.join("\n"))

    @record = record

    messages = record&.destruction_error_messages.to_a
    @errors =
      if messages.any?
        { field_name.to_sym => messages }
      else
        {}
      end

    @error_full_messages =
      if field_name == :base
        messages
      else
        messages.map do |m|
          ActiveModel::Error.new(@record, field_name, m).full_message
        end
      end
  end
end
