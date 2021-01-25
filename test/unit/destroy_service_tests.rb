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

  class ReceiverInitTests < ReceiverTests
    desc "when init"
    subject{ receiver_class.new(exception: exception) }

    let(:exception){ nil }
  end

  class ReceiverInitAroundCallCallbackTests < ReceiverInitTests
    desc "around_call callback"
    setup do
      Assert.stub(
        MuchRails::DestroyService::ValidationErrors,
        :exception_classes,
      ){ exception_classes }
      Assert.stub_on_call(
        MuchRails::DestroyService::ValidationErrors,
        :result_for,
      ) do |call|
        @result_for_call = call
        validation_error_result
      end
    end

    let(:exception){ exceptions.sample }
    let(:exceptions) do
      [
        RuntimeError.new(Factory.string),
        ArgumentError.new(Factory.string),
        MuchRails::Records::DestructionInvalid.new(FakeRecord.new),
      ]
    end
    let(:exception_classes){ exceptions.map(&:class) }
    let(:validation_error_result) do
      MuchResult.failure(error: result_error_message)
    end
    let(:result_error_message){ Factory.string }

    should "rescue raised exceptions and "\
           "use the ValidationErrors to build a result" do
      result = subject.call

      assert_that(result.failure?).is_true
      assert_that(result.error).equals(result_error_message)
    end
  end

  class ValidationErrorsTests < UnitTests
    desc "ValidationErrors"
    subject{ unit_class::ValidationErrors }

    should have_imeths :add, :exception_classes, :result_for
    should have_imeths :service_validation_errors

    should "know its ServiceValidationErrors" do
      assert_that(subject.service_validation_errors)
        .is_an_instance_of(MuchRails::ServiceValidationErrors)
      assert_that(subject.service_validation_errors.exception_classes)
        .includes(MuchRails::Records::DestructionInvalid)
    end
  end

  class ValidationErrorsAddTests < ValidationErrorsTests
    desc ".add"

    setup do
      Assert.stub_on_call(subject.service_validation_errors, :add) do |call|
        @add_call = call
      end
    end

    let(:exception_class){ StandardError }
    let(:block){ proc{ MuchResult.failure } }

    should "call #add on its ServiceValidationErrors" do
      subject.add(exception_class, &block)
      assert_that(@add_call.args).equals([exception_class])
      assert_that(@add_call.block).is(block)
    end
  end

  class ValidationErrorsExceptionClassesTests < ValidationErrorsTests
    desc ".exception_classes"

    setup do
      Assert.stub(
        subject.service_validation_errors,
        :exception_classes,
      ){ exception_classes }
    end

    let(:exception_classes) do
      [
        StandardError,
        ArgumentError,
      ]
    end

    should "call #exception_classes on its ServiceValidationErrors" do
      assert_that(subject.exception_classes).is(exception_classes)
    end
  end

  class ValidationErrorsResultForTests < ValidationErrorsTests
    desc ".result_for"

    setup do
      Assert.stub_on_call(
        subject.service_validation_errors,
        :result_for,
      ) do |call|
        @result_for_call = call
        result_for_result
      end
    end

    let(:exception){ StandardError.new(Factory.string) }
    let(:result_for_result){ MuchResult.failure }

    should "call #result_for on its ServiceValidationErrors" do
      assert_that(subject.result_for(exception)).is(result_for_result)
      assert_that(@result_for_call.args).equals([exception])
    end
  end

  class ValidationErrorsResultForDestructionInvalidTests < ValidationErrorsTests
    desc "when .result_for is passed an MuchRails::Records::DestructionInvalid"

    let(:exception){ MuchRails::Records::DestructionInvalid.new(record) }
    let(:record){ FakeRecord.new }

    should "return a failure result with the record and validation errors" do
      result = subject.result_for(exception)

      assert_that(result.failure?).is_true
      assert_that(result.exception).equals(exception)
      assert_that(result.validation_errors).equals(exception.errors.to_h)
      assert_that(result.validation_error_messages)
        .equals(exception.error_full_messages.to_a)
    end
  end

  class FakeRecord
    def destruction_error_messages
      ["ERROR1", "ERROR2"]
    end
  end
end
