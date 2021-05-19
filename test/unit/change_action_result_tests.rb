# frozen_string_literal: true

require "assert"
require "much-rails/change_action_result"

class MuchRails::ChangeActionResult
  class UnitTests < Assert::Context
    desc "MuchRails::ChangeActionResult"
    subject{ unit_class }

    let(:unit_class){ MuchRails::ChangeActionResult }

    let(:value1){ "VALUE1" }

    should have_imeths :success, :failure

    should "know its attributes" do
      result = unit_class.success(value: value1)

      assert_that(result.success?).is_true
      assert_that(result.failure?).is_false
      assert_that(result.value).equals(value1)

      result = unit_class.failure(value: value1)

      assert_that(result.success?).is_false
      assert_that(result.failure?).is_true
      assert_that(result.value).equals(value1)
    end
  end

  class InitTests < UnitTests
    desc "when init"
    subject{ unit_class.success(value: value1) }

    let(:save_service_result) do
      [
        MuchRails::Result.success,
        MuchRails::Result.failure,
      ].sample
    end

    should have_readers :service_result

    should have_imeths :validation_errors, :validation_error_messages
    should have_imeths :extract_validation_error
    should have_imeths :any_unextracted_validation_errors?

    should "know its service_result" do
      service_result = subject.service_result

      assert_that(service_result).is_instance_of(MuchRails::Result)
      assert_that(service_result.success?).is_true
      assert_that(service_result.value).equals(value1)
      assert_that(service_result.validation_errors).equals({})
    end

    should "raise a TypeError when given a non-MuchRails::Result" do
      assert_that{ unit_class.new(["INVALID TYPE", nil, -9].sample) }
        .raises(TypeError)
    end
  end

  class ValidationMethodsTests < UnitTests
    desc "validation methods"
    subject do
      unit_class.failure(
        validation_errors: {
          name: ["NAME ERROR"],
          other: ["OTHER ERROR"],
          empty: [],
          none: nil,
        },
      )
    end

    should "know its attributes" do
      # validation_errors
      assert_that(subject.validation_errors)
        .equals({
          name: ["NAME ERROR"],
          other: ["OTHER ERROR"],
          empty: [],
          none: [nil],
        })

      # validation_error_messages
      assert_that(subject.validation_error_messages)
        .equals([
          "NAME ERROR",
          "OTHER ERROR",
        ])

      # extract_validation_error
      assert_that(subject.extract_validation_error(:name))
        .equals(["NAME ERROR"])
      assert_that(subject.extract_validation_error(:other))
        .equals(["OTHER ERROR"])
      assert_that(subject.extract_validation_error(:empty))
        .equals([])
      assert_that(subject.extract_validation_error(:none))
        .equals([])
      assert_that(subject.extract_validation_error(:unknown))
        .equals([])
      assert_that(subject.validation_errors).is_empty

      # any_unextracted_validation_errors?
      Assert.stub(subject, :failure?){ true }
      Assert.stub(subject, :validation_errors){ { name: "NAME ERROR" } }
      assert_that(subject.any_unextracted_validation_errors?).is_true

      Assert.stub(subject, :failure?){ true }
      Assert.stub(subject, :validation_errors){ {} }
      assert_that(subject.any_unextracted_validation_errors?).is_false

      Assert.stub(subject, :failure?){ false }
      Assert.stub(subject, :validation_errors){ { name: "NAME ERROR" } }
      assert_that(subject.any_unextracted_validation_errors?).is_false

      Assert.stub(subject, :failure?){ false }
      Assert.stub(subject, :validation_errors){ {} }
      assert_that(subject.any_unextracted_validation_errors?).is_false
    end
  end
end
