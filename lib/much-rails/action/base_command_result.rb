# frozen_string_literal: true

require "much-rails/action/base_result"

module MuchRails; end
module MuchRails::Action; end

# MuchRails::Action::BaseCommandResult is a base result that, when
# executed, runs a generic controller command with some given args.
class MuchRails::Action::BaseCommandResult < MuchRails::Action::BaseResult
  attr_reader :command_name, :command_args

  def initialize(command_name, *command_args)
    @command_name = command_name
    @command_args = command_args
  end

  # This block is called using `instance_exec` in the scope of the controller
  def execute_block
    ->(result) { public_send(result.command_name, *result.command_args) }
  end
end
