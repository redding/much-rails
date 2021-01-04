# frozen_string_literal: true

require "assert"
require "much-rails/save_service"

module MuchRails::SaveService
  class UnitTests < Assert::Context
    desc "MuchRails::SaveService"
    subject { unit_class }

    let(:unit_class) { MuchRails::SaveService }

    should "include MuchRails::Plugin" do
      assert_that(subject).includes(MuchRails::Plugin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject { receiver_class }

    let(:receiver_class) {
      Class.new do
        include MuchRails::SaveService

        def initialize(exception: nil)
          @exception = exception
        end

        def on_call
          raise @exception if @exception

          MuchRails::Result.success
        end
      end
    }

    should "include MuchRails::Service" do
      assert_that(subject).includes(MuchRails::Service)
    end

    should "return success" do
      assert_that(subject.call.success?).is_true
    end
  end

  class RecordInvalidErrorSetupTests < ReceiverTests
    desc "with an ActiveRecord::RecordInvalid error"
    setup do
      Assert.stub(exception, :record) { record }
    end

    let(:exception) { ActiveRecord::RecordInvalid.new }
  end

  class ExceptionWithRecordErrorsTests < RecordInvalidErrorSetupTests
    desc "with an exception that has record errors"

    let(:record) { @fake_record ||= FakeRecord.new }

    should "return a failure result with the exception and record errors" do
      result = subject.call(exception: exception)

      assert_that(result.failure?).is_true
      assert_that(result.exception).equals(exception)
      assert_that(result.validation_errors)
        .equals(some_field: %w[ERROR1 ERROR2])
      assert_that(result.validation_error_messages)
        .equals(["some_field ERROR1", "some_field ERROR2"])
    end
  end

  class ExceptionWithoutRecordErrorsTests < RecordInvalidErrorSetupTests
    desc "with an exception that has no record errors"

    let(:record) { nil }

    should "return a failure result with the exception and empty "\
           "record errors" do
      result = subject.call(exception: exception)

      assert_that(result.failure?).is_true
      assert_that(result.exception).equals(exception)
      assert_that(result.validation_errors).equals({})
      assert_that(result.validation_error_messages).equals([])
    end
  end

  class FakeRecord
    def errors
      Errors.new
    end

    class Errors
      def to_h
        { some_field: %w[ERROR1 ERROR2] }
      end

      def full_messages
        ["some_field ERROR1", "some_field ERROR2"]
      end
    end
  end
end
