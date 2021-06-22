# frozen_string_literal: true

require "assert"
require "much-rails/config"

module MuchRails::Config
  class UnitTests < Assert::Context
    desc "MuchRails::Config"
    subject{ unit_class }

    let(:unit_class){ MuchRails::Config }

    should "be MuchConfig" do
      assert_that(unit_class).is(MuchConfig)
    end
  end
end
