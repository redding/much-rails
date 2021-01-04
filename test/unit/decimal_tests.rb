# frozen_string_literal: true

require "assert"
require "much-rails/decimal"

module MuchRails::Decimal
  class UnitTests < Assert::Context
    desc "MuchRails::Decimal"
    subject { unit_class }

    let(:unit_class) { MuchRails::Decimal }

    should "be MuchDecimal" do
      assert_that(unit_class).is(MuchDecimal)
    end
  end
end
