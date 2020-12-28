# frozen_string_literal: true

# MuchRails::Action::BaseResult is a base result returned by calling
# a view action. Its only purpose is to provide an `execute_block` that
# defines what commands the controller should execute. This block is called
# using `instance_exec` in the scope of the controller.
module MuchRails; end
module MuchRails::Action; end
class MuchRails::Action::BaseResult
  def execute_block
    raise NotImplementedError
  end
end
