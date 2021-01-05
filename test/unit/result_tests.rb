# frozen_string_literal: true

require "assert"
require "much-rails/result"

class MuchRails::Result
  class UnitTests < Assert::Context
    desc "MuchRails::Result"
    subject{ unit_class }

    let(:unit_class){ MuchRails::Result }

    should "be MuchResult" do
      assert_that(unit_class).is(MuchResult)
    end
  end
end
