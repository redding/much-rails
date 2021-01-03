# frozen_string_literal: true

require "much-rails/action/base_command_result"

module MuchRails; end
module MuchRails::Action; end

# MuchRails::Action::SendFileResult is a command result for the `send_file`
# controller response command.
class MuchRails::Action::SendFileResult < MuchRails::Action::BaseCommandResult
  def initialize(*send_file_args)
    super(:send_file, *send_file_args)
  end

  def send_file_args
    command_args
  end
end
