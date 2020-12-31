# frozen_string_literal: true

require "much-rails/plugin"
require "much-rails/change_action"

module MuchRails; end
module MuchRails::SaveAction
  include MuchRails::Plugin

  plugin_included do
    include MuchRails::ChangeAction
  end

  plugin_class_methods do
    def save_result(&block)
      change_result(&block)
    end
  end

  plugin_instance_methods do
    def save_result
      change_result
    end

    private

    def undefined_change_result_block_error_message
      "A `save_result` block must be defined."
    end
  end
end