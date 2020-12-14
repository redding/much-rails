require "assert"

module MuchRails
  class UnitTests < Assert::Context
    desc "MuchRails"
    subject { unit_class }

    let(:unit_class) { Assert }

    should "be" do
      assert_that(unit_class).is_not_nil
    end
  end
end
