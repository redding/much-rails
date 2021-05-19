# frozen_string_literal: true

require "assert"
require "much-rails/invalid_error"

class MuchRails::InvalidError
  class UnitTests < Assert::Context
    desc "MuchRails::InvalidError"
    subject{ unit_class }

    let(:unit_class){ MuchRails::InvalidError }

    should "be configured as expected" do
      assert_that(subject < StandardError).is_true
    end
  end

  class InitSetupTests < UnitTests
    desc "when init"
    subject{ unit_class.new }

    should have_readers :errors
    should have_imeths :error_messages

    should "know its attributes" do
      assert_that(subject.backtrace).is_nil
      assert_that(subject.errors).equals({})
      assert_that(subject.message).equals(subject.errors.inspect)
      assert_that(subject.error_messages).equals([])

      backtrace = Array.new(Factory.integer(3)){ Factory.path }
      errors =
        {
          field1: ["ERROR 1A", "ERROR 2B"],
          field2: "ERROR 2A",
        }
      exception = unit_class.new(backtrace: backtrace, **errors)
      assert_that(exception.backtrace).equals(backtrace)
      assert_that(exception.errors).equals(errors)
      assert_that(exception.message).equals(exception.errors.inspect)
      assert_that(exception.error_messages)
        .equals(["field1: ERROR 1A and ERROR 2B", "field2: ERROR 2A"])
    end
  end
end
