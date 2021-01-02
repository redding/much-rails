# frozen_string_literal: true

require "much-rails/action/base_command_result"

module MuchRails; end
module MuchRails::Action; end

# MuchRails::Action::RedirectToResult is a command result for the
# `redirect_to` controller response command.
class MuchRails::Action::RedirectToResult < MuchRails::Action::BaseCommandResult
  def initialize(*redirect_to_args)
    super(:redirect_to, *redirect_to_args)
  end

  def redirect_to_args
    command_args
  end
end
