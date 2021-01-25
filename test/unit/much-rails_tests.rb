# frozen_string_literal: true

require "assert"
require "much-rails"

module MuchRails
  class UnitTests < Assert::Context
    desc "MuchRails"
    subject{ unit_class }

    let(:unit_class){ MuchRails }

    should have_imeths :config, :configure_much_rails, :configure

    should "be configured as expected" do
      assert_that(subject).includes(MuchRails::Config)
      assert_that(subject).includes(MuchRails::NotGiven)
      assert_that(subject.config).is_not_nil
    end
  end

  class ConfigTests < UnitTests
    desc ".config"
    subject{ unit_class.config }

    should have_imeths :action, :layout
    should have_imeths :add_save_service_validation_error
    should have_imeths :add_destroy_service_validation_error

    should "be configured as expected" do
      assert_that(subject.action).is_not_nil
      assert_that(subject.layout).is_not_nil
    end
  end

  class ConfigServiceValidationErrorTests < ConfigTests
    setup do
      Assert.stub_on_call(
        MuchRails::SaveService::ValidationErrors,
        :add,
      ) do |call|
        @save_service_validation_errors_add_call = call
      end
      Assert.stub_on_call(
        MuchRails::DestroyService::ValidationErrors,
        :add,
      ) do |call|
        @destroy_service_validation_errors_add_call = call
      end
    end

    let(:exception_class){ StandardError }
    let(:block){ proc{ MuchResult.failure } }

    should "know how to add an exception class "\
           "to the save service validation errors" do
      subject.add_save_service_validation_error(exception_class, &block)
      assert_that(@save_service_validation_errors_add_call.args)
        .equals([exception_class])
      assert_that(@save_service_validation_errors_add_call.block)
        .is(block)
    end

    should "know how to add an exception class "\
           "to the destroy service validation errors" do
      subject.add_destroy_service_validation_error(exception_class, &block)
      assert_that(@destroy_service_validation_errors_add_call.args)
        .equals([exception_class])
      assert_that(@destroy_service_validation_errors_add_call.block)
        .is(block)
    end
  end

  class ActionConfigTests < UnitTests
    desc ".action"
    subject{ unit_class.config.action }

    should have_accessors :namespace
    should have_accessors :sanitized_exception_classes
    should have_accessors :raise_response_exceptions

    should have_imeths :raise_response_exceptions?

    should "be configured as expected" do
      assert_that(subject.namespace).equals("")
      assert_that(subject.sanitized_exception_classes)
        .equals([ActiveRecord::RecordInvalid])
      assert_that(subject.raise_response_exceptions).is_false
      assert_that(subject.raise_response_exceptions?).is_false
    end
  end
end
