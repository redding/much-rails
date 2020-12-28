# frozen_string_literal: true

require "much-rails/action/base_command_result"

# MuchRails::Action::SendDataResult is a command result for the `send_data`
# controller response command.
module MuchRails; end
module MuchRails::Action; end
class MuchRails::Action::SendDataResult < MuchRails::Action::BaseCommandResult
  def initialize(*send_data_args)
    super(:send_data, *send_data_args)
  end

  def send_data_args
    command_args
  end
end
