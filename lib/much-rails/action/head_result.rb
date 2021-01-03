# frozen_string_literal: true

require "much-rails/action/base_command_result"

module MuchRails; end
module MuchRails::Action; end

# MuchRails::Views::HeadResult is a command result for the `head` controller
# response command.
class MuchRails::Action::HeadResult < MuchRails::Action::BaseCommandResult
  def initialize(*head_args)
    super(:head, *head_args)
  end

  def head_args
    command_args
  end
end
