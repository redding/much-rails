# frozen_string_literal: true

require "much-rails/mixin"
require "much-rails/change_action"

module MuchRails; end

module MuchRails::SaveAction
  include MuchRails::Mixin

  mixin_included do
    include MuchRails::ChangeAction
  end

  mixin_class_methods do
    def save_result(&block)
      change_result(&block)
    end
  end

  mixin_instance_methods do
    def save_result
      change_result
    end

    private

    def undefined_change_result_block_error_message
      "A `save_result` block must be defined."
    end
  end
end
