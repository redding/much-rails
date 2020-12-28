require "assert"
require "much-rails/not_given"

module MuchRails::NotGiven
  class UnitTests < Assert::Context
    desc "MuchRails::NotGiven"
    subject { unit_class }

    let(:unit_class) { MuchRails::NotGiven }

    should "be MuchNotGiven" do
      assert_that(unit_class).is(MuchNotGiven)
    end
  end
end
