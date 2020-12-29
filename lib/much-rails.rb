# frozen_string_literal: true

require "active_support"
require "active_support/core_ext"

require "much-rails/version"
require "much-rails/boolean"
require "much-rails/call_method"
require "much-rails/call_method_callbacks"
require "much-rails/change_action_result"
require "much-rails/config"
require "much-rails/date"
require "much-rails/decimal"
require "much-rails/destroy_service"
require "much-rails/has_slug"
require "much-rails/input_value"
require "much-rails/json"
require "much-rails/not_given"
require "much-rails/plugin"
require "much-rails/records"
require "much-rails/result"
require "much-rails/save_service"
require "much-rails/service"
require "much-rails/time"
require "much-rails/wrap_and_call_method"
require "much-rails/wrap_method"

require "much-rails/railtie" if defined?(Rails::Railtie)

module MuchRails
end
