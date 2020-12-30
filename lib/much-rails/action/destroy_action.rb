# frozen_string_literal: true

require "much-rails/plugin"
require "much-rails/action/change_action"

# MuchRails::Action::DestroyAction defines the common behaviors for all view
# action classes that destroy records.
module MuchRails; end
module MuchRails::Action; end
module MuchRails::Action::DestroyAction
  include MuchRails::Plugin

  plugin_included do
    include MuchRails::Action::ChangeAction
  end

  plugin_class_methods do
    def destroy_result(&block)
      change_result(&block)
    end
  end

  plugin_instance_methods do
    def destroy_result
      change_result
    end

    private

    def undefined_change_result_block_error_message
      "A `destroy_result` block must be defined."
    end
  end
end
