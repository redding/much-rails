# frozen_string_literal: true

require "assert"
require "much-rails/destroy_service"

module MuchRails::DestroyService
  class UnitTests < Assert::Context
    desc "MuchRails::DestroyService"
    subject{ unit_class }

    let(:unit_class){ MuchRails::DestroyService }

    should "include MuchRails::Mixin" do
      assert_that(subject).includes(MuchRails::Mixin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject{ receiver_class }

    let(:receiver_class) do
      Class.new do
        include MuchRails::DestroyService

        def initialize(exception: nil)
          @exception = exception
        end

        def on_call
          raise @exception if @exception

          MuchRails::Result.success
        end
      end
    end

    should "include MuchRails::Service" do
      assert_that(subject).includes(MuchRails::Service)
    end

    should "return success" do
      assert_that(subject.call.success?).is_true
    end
  end

  class DestructionInvalidErrorSetupTests < ReceiverTests
    desc "with a MuchRails::Records::DestructionInvalid error"
    setup do
      Assert.stub(exception, :record){ record }
    end

    let(:exception){ MuchRails::Records::DestructionInvalid.new }
  end

  class ExceptionWithDestructionErrorMessagesTests <
          DestructionInvalidErrorSetupTests
    desc "with an exception record that has destruction_error_messages"

    let(:record){ @fake_record ||= FakeRecord.new }

    should "return a failure result with the exception and validation_errors" do
      result = subject.call(exception: exception)

      assert_that(result.failure?).is_true
      assert_that(result.record).is(record)
      assert_that(result.exception).equals(exception)
      assert_that(result.validation_errors).equals(exception.errors)
      assert_that(result.validation_error_messages)
        .equals(exception.error_full_messages)
    end
  end

  class ExceptionWithoutDestructionErrorMessagesTests <
          DestructionInvalidErrorSetupTests
    desc "with an exception record that has no destruction_error_messages"

    let(:record){ nil }

    should "return a failure result with the exception and empty "\
           "validation_errors" do
      result = subject.call(exception: exception)

      assert_that(result.failure?).is_true
      assert_that(result.record).is_nil
      assert_that(result.exception).equals(exception)
      assert_that(result.validation_errors).equals(exception.errors)
      assert_that(result.validation_error_messages)
        .equals(exception.error_full_messages)
    end
  end

  class FakeRecord
    def destruction_error_messages
      ["ERROR1", "ERROR2"]
    end
  end
end
