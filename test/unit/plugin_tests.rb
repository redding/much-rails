# frozen_string_literal: true

require "assert"
require "much-rails/plugin"

module MuchRails::Plugin
  class UnitTests < Assert::Context
    desc "MuchRails::Plugin"
    subject { unit_class }

    let(:unit_class) { MuchRails::Plugin }

    should "be MuchPlugin" do
      assert_that(unit_class).is(MuchPlugin)
    end
  end
end
