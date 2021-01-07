# frozen_string_literal: true

require "assert"
require "much-rails/mixin"

module MuchRails::Mixin
  class UnitTests < Assert::Context
    desc "MuchRails::Mixin"
    subject { unit_class }

    let(:unit_class) { MuchRails::Mixin }

    should "be MuchMixin" do
      assert_that(unit_class).is(MuchMixin)
    end
  end
end
