# frozen_string_literal: true

require "assert"
require "much-rails/input_value"

module MuchRails::InputValue
  class UnitTests < Assert::Context
    desc "MuchRails::InputValue"
    subject { unit_class }

    let(:unit_class) { MuchRails::InputValue }

    should have_imeths :strip, :strip_all

    should "know its attributes" do
      # strip
      input_value = [nil, "", " "].sample
      assert_that(subject.strip(input_value)).is_nil

      input_value = [" VALUE  ", "\r VALUE\n"].sample
      assert_that(subject.strip(input_value)).equals("VALUE")

      assert_that(subject.strip([])).is_nil
      assert_that(subject.strip({})).is_nil

      # strip_all
      input_values = [nil, "", " ", " VALUE  "]
      assert_that(subject.strip_all(input_values)).equals(["VALUE"])

      input_values = [" VALUE1  ", "\r VALUE2\n"]
      assert_that(subject.strip_all(input_values)).equals(["VALUE1", "VALUE2"])
    end
  end
end
