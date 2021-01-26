# frozen_string_literal: true

require "assert"
require "much-rails/records/validate_destroy"

module MuchRails::Records::ValidateDestroy
  class UnitTests < Assert::Context
    desc "MuchRails::Records::ValidateDestroy"
    subject{ unit_class }

    let(:unit_class){ MuchRails::Records::ValidateDestroy }

    should "include MuchRails::Mixin" do
      assert_that(subject).includes(MuchRails::Mixin)
    end
  end

  class ReceiverTests < UnitTests
    desc "when init"
    subject{ receiver_class.new }

    setup do
      Assert.stub_tap_on_call(subject, :destroy!) do |_, call|
        @destroy_bang_call = call
      end
    end

    let(:receiver_class){ FakeRecordMissingValidateDestroyClass }

    should have_imeths :destruction_error_messages
    should have_imeths :destroy, :destroy!
    should have_imeths :destroyable?, :not_destroyable?

    should "not implement its #validate_destroy method" do
      assert_that(->{ subject.instance_eval{ validate_destroy } })
        .raises(NotImplementedError)
    end
  end

  class ReceiverWithDestructionErrorMessagesTests < ReceiverTests
    desc "with destruction error messages"
    setup do
      subject.destruction_errors_exist = true
    end

    let(:receiver_class){ FakeRecordClass }

    should "validate destroying records" do
      subject.destroyable?
      assert_that(subject.destruction_error_messages)
        .equals(["TEST DESTRUCTION ERROR1", "TEST DESTRUCTION ERROR2"])

      subject.destroy
      assert_that(subject.super_destroy_called).is_nil

      subject.destroy(validate: false)
      assert_that(subject.super_destroy_called).is_true

      subject.super_destroy_called = nil
      subject.destroy_without_validation
      assert_that(subject.super_destroy_called).is_true

      exception =
        assert_that(->{ subject.destroy! })
          .raises(MuchRails::Records::DestructionInvalid)
      assert_that(exception.message)
        .equals("TEST DESTRUCTION ERROR1\nTEST DESTRUCTION ERROR2")
      assert_that(exception.errors)
        .equals(base: subject.destruction_error_messages.to_a)
      assert_that(subject.super_destroy_called).is_true

      exception =
        assert_that(->{ subject.destroy!(as: :thing) })
          .raises(MuchRails::Records::DestructionInvalid)
      assert_that(exception.errors)
        .equals(thing: subject.destruction_error_messages.to_a)

      subject.super_destroy_called = nil
      subject.destroy!(validate: false)
      assert_that(subject.super_destroy_called).is_true

      @destroy_bang_call = nil
      subject.destroy_without_validation!
      assert_that(@destroy_bang_call.args).equals([as: :base, validate: false])

      @destroy_bang_call = nil
      subject.destroy_without_validation!(as: :thing)
      assert_that(@destroy_bang_call.args).equals([as: :thing, validate: false])

      assert_that(subject.destroyable?).is_false
      assert_that(subject.not_destroyable?).is_true
    end
  end

  class ReceiverWithNoDestructionErrorMessagesTests < ReceiverTests
    desc "with no destruction error messages"
    setup do
      subject.destruction_errors_exist = false
    end

    let(:receiver_class){ FakeRecordClass }

    should "validate destroying records" do
      subject.destroyable?
      assert_that(subject.destruction_error_messages).equals([])

      subject.destroy
      assert_that(subject.super_destroy_called).is_true

      subject.super_destroy_called = nil
      subject.destroy_without_validation
      assert_that(subject.super_destroy_called).is_true

      subject.super_destroy_called = nil
      subject.destroy!
      assert_that(subject.super_destroy_called).is_true

      @destroy_bang_call = nil
      subject.destroy_without_validation!
      assert_that(@destroy_bang_call.args).equals([as: :base, validate: false])

      assert_that(subject.destroyable?).is_true
      assert_that(subject.not_destroyable?).is_false
    end
  end

  class DestroyFalseTests < ReceiverTests
    desc "when #destroy returns false"
    setup do
      Assert.stub(subject, :destroy){ false }
    end

    let(:receiver_class){ FakeRecordClass }

    should "raise ActiveRecord::RecordNotDestroyed" do
      assert_that(->{ subject.destroy! })
        .raises(ActiveRecord::RecordNotDestroyed)
    end
  end

  class DestructionInvalidTests < UnitTests
    desc "MuchRails::Records::DestructionInvalid"
    subject{ exception_class }

    let(:exception_class){ MuchRails::Records::DestructionInvalid }

    let(:record){ FakeRecordClass.new }

    should "be configured as expected" do
      assert_that(subject < StandardError).is_true
    end
  end

  class DestructionInvalidInitTests < DestructionInvalidTests
    desc "when init"
    subject{ exception_class.new(record) }

    should have_readers :record, :errors, :error_full_messages

    should "know its attributes when destruction errors exist" do
      record.destruction_errors_exist = true
      record.validate_destroy

      assert_that(subject.message)
        .equals(record.destruction_error_messages.to_a.join("\n"))
      assert_that(subject.record).is(record)
      assert_that(subject.errors).equals(
        base: record.destruction_error_messages.to_a,
      )
      assert_that(subject.error_full_messages)
        .equals(record.destruction_error_messages.to_a)
    end

    should "know its attributes when destruction errors don't exist" do
      assert_that(subject.message).equals("")
      assert_that(subject.record).is(record)
      assert_that(subject.errors).equals({})
      assert_that(subject.error_full_messages).equals([])
    end
  end

  class DestructionInvalidInitWithFieldNameTests < DestructionInvalidTests
    desc "when init with a field name"
    subject{ exception_class.new(record, field_name: field_name) }

    let(:field_name){ Factory.string }

    should "know its attributes when destruction errors exist" do
      record.destruction_errors_exist = true
      record.validate_destroy

      assert_that(subject.message)
        .equals(record.destruction_error_messages.to_a.join("\n"))
      assert_that(subject.record).is(record)
      assert_that(subject.errors).equals(
        field_name.to_sym => record.destruction_error_messages.to_a,
      )
      assert_that(subject.error_full_messages)
        .equals(
          record
            .destruction_error_messages
            .map do |m|
              ActiveModel::Error.new(record, field_name, m).full_message
            end,
        )
    end

    should "know its attributes when destruction errors don't exist" do
      assert_that(subject.message).equals("")
      assert_that(subject.record).is(record)
      assert_that(subject.errors).equals({})
      assert_that(subject.error_full_messages).equals([])
    end
  end

  require "active_record"

  class FakeRecordBaseClass
    extend ActiveRecord::Translation
    # Include ActiveRecord::Persistence to test the `destroy!` logic
    # (the `_raise_record_not_destroyed` method) that we had to re-implement in
    # the MuchRails::Records::ValidateDestroy.
    include ActiveRecord::Persistence

    attr_accessor :super_destroy_called

    attr_accessor :destruction_errors_exist

    def self.base_class?
      true
    end

    def destroy
      @super_destroy_called = true
    end
  end

  class FakeRecordClass < FakeRecordBaseClass
    include MuchRails::Records::ValidateDestroy

    def validate_destroy
      return unless destruction_errors_exist

      destruction_error_messages << "TEST DESTRUCTION ERROR1"
      destruction_error_messages << "TEST DESTRUCTION ERROR2"
    end
  end

  class FakeRecordMissingValidateDestroyClass < FakeRecordBaseClass
    include MuchRails::Records::ValidateDestroy
  end
end
