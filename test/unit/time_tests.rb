# frozen_string_literal: true

require "assert"
require "much-rails/time"

module MuchRails::Time
  class UnitTests < Assert::Context
    desc "MuchRails::Time"
    subject{ unit_class }

    let(:unit_class){ MuchRails::Time }

    let(:time){ Time.current }
    let(:utc_time){ time.utc }

    should have_imeths :for

    should "know how to convert time-like representations to Time" do
      # nil, blank value(s)
      assert_that(subject.for(nil)).is_nil
      ["", " "].each do |object|
        assert_that(subject.for(object)).is_nil
      end

      # Time, DateTime, or Date
      objects = [Time.current, DateTime.current, Date.today]
      objects.each do |object|
        assert_that(subject.for(object)).equals(object.to_time)
      end

      # U.S.-formatted String
      result = subject.for(time.iso8601)

      assert_that(result).is_instance_of(Time)
      assert_that(result.utc?).is_true
      assert_that(result.year).equals(utc_time.year)
      assert_that(result.month).equals(utc_time.month)
      assert_that(result.day).equals(utc_time.day)
      assert_that(result.hour).equals(utc_time.hour)
      assert_that(result.min).equals(utc_time.min)
      assert_that(result.sec).equals(utc_time.sec)

      # invalid values
      invalid_objects = ["TEST_VALUE", 42, Class.new]
      invalid_objects.each do |object|
        assert_that(->{ subject.for(object) })
          .raises(MuchRails::Time::InvalidError)
      end
    end
  end
end
