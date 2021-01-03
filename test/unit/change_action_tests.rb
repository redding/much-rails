require "assert"
require "much-rails/change_action"

module MuchRails::ChangeAction
  class UnitTests < Assert::Context
    desc "MuchRails::ChangeAction"
    subject { unit_class }

    let(:unit_class) { MuchRails::ChangeAction }

    should "include MuchRails::Plugin" do
      assert_that(subject).includes(MuchRails::Plugin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject { receiver_class }

    let(:receiver_class) {
      Class.new do
        include MuchRails::ChangeAction

        change_result { MuchRails::Result.success(something: something_value) }

        on_call {}

        def something_value
          "SOMETHING VALUE"
        end

        private

        def undefined_change_result_block_error_message
          "UNDEFINED CHANGE RESULT BLOCK"
        end
      end
    }

    should have_imeths :change_result

    should "be configured as expected" do
      assert_that(subject).includes(MuchRails::Config)
      assert_that(subject).includes(MuchRails::Action)

      assert_that(subject.much_rails_change_action_config)
        .is_instance_of(
          MuchRails::ChangeAction::MuchRailsChangeActionConfig
        )
      assert_that(
        subject.much_rails_change_action_config.change_result_block
      ).is_not_nil
    end
  end

  class InitTests < ReceiverTests
    desc "when init"
    subject { receiver_class.new(params: {}) }
    subject {
      receiver_class.new(
        params: {},
        current_user: nil,
        request: nil,
      )
    }

    setup do
      Assert.stub(subject, :any_unextracted_change_result_validation_errors?) {
        false
      }
    end

    should have_imeths :change_result

    should "render the default response" do
      result = subject.call

      assert_that(result.command_name).equals(:head)
      assert_that(result.command_args).equals([:ok])
    end
  end

  class RecordErrorsWithResultExceptionTests < InitTests
    desc "with record errors and a result exception"
    subject {
      receiver_class.new(
        params: {},
        current_user: nil,
        request: nil,
      )
    }

    setup do
      Assert.stub(subject, :any_unextracted_change_result_validation_errors?) {
        true
      }
      Assert.stub(result_exception, :message) { "ERROR MESSAGE" }
      Assert.stub(result_exception, :backtrace) { ["BACKTRACE LINE1"] }

      Assert.stub(subject, :change_result) { change_result1 }
    end

    let(:result_exception) { RuntimeError.new }
    let(:change_result1) {
      MuchRails::Result.failure(exception: result_exception)
    }

    should "raise a MuchRails::Action::ActionError" do
      exception =
        assert_that { subject.call }.raises(MuchRails::Action::ActionError)

      assert_that(exception.message).equals("ERROR MESSAGE")
      assert_that(exception.backtrace).equals(["BACKTRACE LINE1"])
    end
  end

  class RecordErrorsWithNoResultExceptionTests < InitTests
    desc "with record errors and no result exception"
    subject {
      receiver_class.new(
        params: {},
        current_user: nil,
        request: nil,
      )
    }

    setup do
      Assert.stub(subject, :any_unextracted_change_result_validation_errors?) {
        true
      }
      Assert.stub(subject, :change_result) { change_result1 }
    end

    let(:change_result1) { MuchRails::Result.failure }

    should "raise a MuchRails::Action::ActionError" do
      exception =
        assert_that { subject.call }.raises(MuchRails::Action::ActionError)

      assert_that(exception.message)
        .equals(
          "#{change_result1.inspect} has validation errors that were not "\
          "handled by the Action: #{change_result1.validation_errors.inspect}."
        )
    end
  end

  class ChangeResultMethodTests < InitTests
    desc "#change_result method"
    subject {
      receiver_class.new(
        params: {},
        current_user: nil,
        request: nil,
      )
    }

    should "memoize and return the expected Result" do
      result = subject.change_result

      assert_that(result.success?).is_true
      assert_that(result.something).equals("SOMETHING VALUE")
      assert_that(result).is(subject.change_result)
    end

    should "raise an error when a configured change_result block is not given" do
      Assert.stub(
        receiver_class.much_rails_change_action_config,
        :change_result_block
      ) { nil }
      exception =
        assert_that { subject.change_result }.raises(unit_class::Error)
      assert_that(exception.message).equals("UNDEFINED CHANGE RESULT BLOCK")
    end
  end

  class AnyUnextractedChangeResultValidationErrorsMethodTests < ReceiverTests
    desc "#any_unextracted_change_result_validation_errors? method"
    subject {
      receiver_class.new(
        params: {},
        current_user: nil,
        request: nil,
      )
    }

    let(:receiver_class) {
      Class.new do
        include MuchRails::ChangeAction

        change_result { MuchRails::Result.success }
      end
    }

    should "return false" do
      subject.change_result

      assert_that(subject.any_unextracted_change_result_validation_errors?)
        .is_false
    end
  end

  class NoValidationErrorsTests < AnyUnextractedChangeResultValidationErrorsMethodTests
    desc "with no validation errors"
    subject {
      receiver_class.new(
        params: {},
        current_user: nil,
        request: nil,
      )
    }

    let(:receiver_class) {
      Class.new do
        include MuchRails::ChangeAction

        change_result { MuchRails::Result.failure(validation_errors: {}) }
      end
    }

    should "return false" do
      subject.change_result

      assert_that(subject.any_unextracted_change_result_validation_errors?)
        .is_false
    end
  end

  class ValidationErrorsTests < AnyUnextractedChangeResultValidationErrorsMethodTests
    desc "with validation errors"
    subject {
      receiver_class.new(
        params: {},
        current_user: nil,
        request: nil,
      )
    }

    let(:receiver_class) {
      Class.new do
        include MuchRails::ChangeAction

        change_result {
          MuchRails::Result.failure(validation_errors: { name: "TEST ERROR" })
        }
      end
    }

    should "return true" do
      subject.change_result

      assert_that(subject.any_unextracted_change_result_validation_errors?)
        .is_true
    end
  end
end
