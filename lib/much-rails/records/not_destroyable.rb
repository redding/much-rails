# frozen_string_literal: true

require "much-rails/plugin"
require "much-rails/records/validate_destroy"

# MuchRails::Records::NotDestroyable is a mix-in to disable destroying a
# record. It mixes-in MuchRails::Records::ValidateDestroy and hard-codes
# a permanent destruction error message.
module MuchRails; end
module MuchRails::Records; end
module MuchRails::Records::NotDestroyable
  include MuchRails::Plugin

  plugin_included do
    include MuchRails::Records::ValidateDestroy
  end

  plugin_instance_methods do
    def destruction_error_messages
      ["#{self.class.name} records can't be deleted."]
    end

    private

    def validate_destroy
      # Do nothing on purpose.
    end
  end
end
