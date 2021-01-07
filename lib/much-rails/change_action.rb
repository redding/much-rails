# frozen_string_literal: true

require "much-rails/action"
require "much-rails/change_action_result"
require "much-rails/config"
require "much-rails/mixin"

module MuchRails; end

module MuchRails::ChangeAction
  Error = Class.new(StandardError)

  include MuchRails::Mixin

  mixin_included do
    include MuchRails::Config
    include MuchRails::Action

    add_config :much_rails_change_action

    on_after_call do
      if any_unextracted_change_result_validation_errors?
        raise(
          MuchRails::Action::ActionError,
          unhandled_change_result_action_error_message,
          unhandled_change_result_action_error_backtrace,
        )
      end
    end
  end

  mixin_class_methods do
    def change_result(&block)
      much_rails_change_action_config.change_result_block = block
    end
  end

  mixin_instance_methods do
    def change_result
      @change_result ||=
        begin
          unless (
            self.class.much_rails_change_action_config.change_result_block
          )
            raise(Error, undefined_change_result_block_error_message)
          end

          MuchRails::ChangeActionResult.new(
            instance_exec(
              &self.class.much_rails_change_action_config.change_result_block
            ),
          )
        end
    end

    # Check the instance variable directly to make sure the main `on_call`
    # block actually called the `change_result` method and memoized a Result.
    # If no Result memoized, there are implicitly no unhandled errors.
    def any_unextracted_change_result_validation_errors?
      !!@change_result&.any_unextracted_validation_errors?
    end

    private

    def unhandled_change_result_action_error_message
      change_result.exception&.message ||
        "#{change_result.inspect} has validation errors that were not handled "\
        "by the Action: #{change_result.validation_errors.inspect}."
    end

    def unhandled_change_result_action_error_backtrace
      change_result.exception&.backtrace || caller
    end

    def undefined_change_result_block_error_message
      raise NotImplementedError
    end
  end

  class MuchRailsChangeActionConfig
    attr_accessor :change_result_block
  end
end
