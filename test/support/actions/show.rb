# frozen_string_literal: true

require "much-rails/action"

module Actions
  class Show
    include MuchRails::Action

    params_root :nested
  end
end
