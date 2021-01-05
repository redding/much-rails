# frozen_string_literal: true

require "much-rails/action/base_result"

module MuchRails; end
module MuchRails::Action; end

# MuchRails::Action::UnprocessableEntityResult is a result returned by
# calling a view action that is not valid. It returns JSON with the validation
# details.
#
# This result is only returned if, after validating the action, there are
# errors. Most commonly this occurs when validating form submission params.
class MuchRails::Action::UnprocessableEntityResult <
        MuchRails::Action::BaseResult
  attr_reader :errors

  def initialize(errors)
    @errors = errors
  end

  # This block is called using `instance_exec` in the scope of the controller
  def execute_block
    ->(result){
      errors =
        Array
          .wrap(much_rails_action_class&.params_root)
          .reduce(result.errors) do |acc, root|
            acc.merge(
              acc.transform_keys{ |error_key| "#{root}[#{error_key}]" },
            )
          end

      render(json: errors, status: :unprocessable_entity)
    }
  end
end
