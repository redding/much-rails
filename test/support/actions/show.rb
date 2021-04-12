# frozen_string_literal: true

require "much-rails/action"

module Actions; end

module Actions::Show
  include MuchRails::Action

  format :html

  params_root :nested
end
