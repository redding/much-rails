# frozen_string_literal: true

require "assert"
require "much-rails/boolean"

class MuchRails::Boolean
  class UnitTests < Assert::Context
    desc "MuchRails::Boolean"
    subject { unit_class }

    let(:unit_class) { MuchRails::Boolean }

    should "be MuchBoolean" do
      assert_that(unit_class).is(MuchBoolean)
    end
  end
end
