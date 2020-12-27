require "assert"
require "much-rails/date"

module MuchRails::Date
  class UnitTests < Assert::Context
    desc "MuchRails::Date"
    subject { unit_class }

    let(:unit_class) { MuchRails::Date }

    let(:time) { Time.current }
    let(:date) { time.to_date }

    should have_imeths :for, :parse, :parse_united_states, :parse8601

    should "know how to convert date-like representations to Date" do
      # nil, blank value(s)
      # assert_that(subject.for(nil)).is_nil
      ["", " "].each { |object| assert_that(subject.for(object)).is_nil }

      # Time, DateTime, or Date
      objects = [Time.current, DateTime.current, Date.today]
      objects.each do |object|
        assert_that(subject.for(object)).equals(object.to_date)
      end

      # U.S.-formatted String
      assert_that(subject.for(time.strftime("%m/%d/%Y"))).equals(date)
      assert_that(subject.for(time.strftime("%m.%d.%Y"))).equals(date)
      assert_that(subject.for(time.strftime("%m-%d-%Y %H:%M:%S"))).equals(date)
      assert_that(subject.for(time.iso8601)).equals(date)

      # iso8601-formatted String
      assert_that(subject.for(time.strftime("%Y-%m-%d"))).equals(date)
      assert_that(subject.for(time.strftime("%Y.%m.%d"))).equals(date)
      assert_that(subject.for(time.strftime("%Y-%m-%d %H:%M:%S"))).equals(date)
      assert_that(subject.for(time.iso8601)).equals(date)

      # invalid values
      invalid_objects = ["VALUE", 42, Class.new]
      invalid_objects.each do |object|
        assert_that(-> { subject.for(object) })
          .raises(MuchRails::Date::InvalidError)
      end
    end
  end
end
