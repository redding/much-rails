# frozen_string_literal: true

class MuchRails::ServiceValidationErrors
  class UnitTests < Assert::Context
    desc "MuchRails::ServiceValidationErrors"
    subject{ unit_class }

    let(:unit_class){ MuchRails::ServiceValidationErrors }
  end

  class InitTests < UnitTests
    desc "when init"
    subject{ unit_class.new }

    should have_readers :hash
    should have_imeths :add, :exception_classes, :result_for
  end

  class InitAddTests < InitTests
    desc "#add"

    let(:exception_class){ StandardError }
    let(:block){ proc{ MuchResult.failure } }

    let(:invalid_exception_class) do
      [
        Class.new,
        Factory.string,
        nil,
      ].sample
    end

    should "add an exception class and block" do
      subject.add(exception_class, &block)
      assert_that(subject.hash[exception_class]).is(block)
    end

    should "raise an error when it's not passed an Exception" do
      assert_that{
        subject.add(invalid_exception_class, &block)
      }.raises(ArgumentError)
    end
  end

  class InitExceptionClassesTests < InitTests
    desc "#exception_classes"

    setup do
      exception_classes.each do |exception_class|
        subject.add(exception_class, &block)
      end
    end

    let(:exception_classes) do
      [
        StandardError,
        ArgumentError,
        RuntimeError,
      ]
    end
    let(:block){ proc{ MuchResult.failure } }

    should "return all the added exception classes" do
      assert_that(subject.exception_classes).equals(exception_classes)
    end
  end

  class InitResultForTests < InitTests
    desc "#result_for"

    setup do
      subject.add(exception_class, &block)
    end

    let(:exception){ exception_class.new(Factory.string) }
    let(:exception_class){ StandardError }
    let(:block) do
      proc{ MuchResult.failure(error_message: failure_result_error_message) }
    end
    let(:failure_result_error_message){ Factory.string }

    let(:inherited_exception){ RuntimeError.new(Factory.string) }

    let(:invalid_exception){ Exception.new(Factory.string) }

    should "return the result of calling the added block "\
           "for the exception class" do
      result = subject.result_for(exception)
      assert_that(result.failure?).is_true
      assert_that(result.error_message).equals(failure_result_error_message)
    end

    should "return the result of calling the added block "\
           "for an exception class ancestor" do
      result = subject.result_for(exception)
      assert_that(result.failure?).is_true
      assert_that(result.error_message).equals(failure_result_error_message)
    end

    should "raise an error if a block hasn't been added "\
           "for the exception class" do
      assert_that{
        subject.result_for(invalid_exception)
      }.raises(ArgumentError)
    end
  end
end
