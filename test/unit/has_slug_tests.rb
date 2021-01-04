# frozen_string_literal: true

require "assert"
require "much-rails/has_slug"

module MuchRails::HasSlug
  class UnitTests < Assert::Context
    desc "MuchRails::HasSlug"
    subject { unit_class }

    let(:unit_class) { MuchRails::HasSlug }

    should "be MuchSlug" do
      assert_that(unit_class).is(MuchSlug)
    end
  end
end
