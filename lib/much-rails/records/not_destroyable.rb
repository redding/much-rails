# frozen_string_literal: true

require "much-rails/mixin"
require "much-rails/records/validate_destroy"

module MuchRails; end
module MuchRails::Records; end

# MuchRails::Records::NotDestroyable is a mix-in to disable destroying a
# record. It mixes-in MuchRails::Records::ValidateDestroy and hard-codes
# a permanent destruction error message.
module MuchRails::Records::NotDestroyable
  include MuchRails::Mixin

  mixin_included do
    include MuchRails::Records::ValidateDestroy
  end

  mixin_instance_methods do
    def destruction_error_messages
      ["#{self.class.name} records can't be deleted."]
    end

    private

    def validate_destroy
      # Do nothing on purpose.
    end
  end
end
