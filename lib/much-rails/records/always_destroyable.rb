# frozen_string_literal: true

require "much-rails/plugin"
require "much-rails/records/validate_destroy"

# MuchRails::Records::AlwaysDestroyable is a mix-in to always enable destroying
# a record. It mixes-in MuchRails::Records::ValidateDestroy and hard-codes
# never adding destruction error messages.
module MuchRails; end
module MuchRails::Records; end
module MuchRails::Records::AlwaysDestroyable
  include MuchRails::Plugin

  plugin_included do
    include MuchRails::Records::ValidateDestroy
  end

  plugin_instance_methods do
    def destruction_error_messages
      []
    end

    private

    def validate_destroy
      # Do nothing on purpose.
    end
  end
end
