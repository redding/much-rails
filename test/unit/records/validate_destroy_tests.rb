require "assert"
require "much-rails/records/validate_destroy"

module MuchRails::Records::ValidateDestroy
  class UnitTests < Assert::Context
    desc "MuchRails::Records::ValidateDestroy"
    subject { unit_class }

    let(:unit_class) { MuchRails::Records::ValidateDestroy }

    should "include MuchRails::Plugin" do
      assert_that(subject).includes(MuchRails::Plugin)
    end
  end

  class ReceiverTests < UnitTests
    desc "when init"
    subject { receiver_class.new }

    setup do
      Assert.stub_tap_on_call(subject, :destroy!) { |_, call|
        @destroy_bang_call = call
      }
    end

    let(:receiver_class) { FakeRecordMissingValidateDestroyClass }

    should have_imeths :destruction_error_messages
    should have_imeths :destroy, :destroy!
    should have_imeths :destroyable?, :not_destroyable?

    should "not implement its #validate_destroy method" do
      assert_that(-> { subject.instance_eval{ validate_destroy } })
        .raises(NotImplementedError)
    end
  end

  class ReceiverWithDestructionErrorMessagesTests < ReceiverTests
    desc "with destruction error messages"
    setup do
      subject.destruction_errors_exist = true
    end

    let(:receiver_class) { FakeRecordClass }

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
        assert_that(-> { subject.destroy! })
          .raises(MuchRails::Records::ValidateDestroy::DestructionInvalid)
      assert_that(exception.message)
        .equals("TEST DESTRUCTION ERROR1\nTEST DESTRUCTION ERROR2")
      assert_that(exception.destruction_errors)
        .equals(base: subject.destruction_error_messages.to_a)
      assert_that(subject.super_destroy_called).is_true

      exception =
        assert_that(-> { subject.destroy!(as: :thing) })
          .raises(MuchRails::Records::ValidateDestroy::DestructionInvalid)
      assert_that(exception.destruction_errors)
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

    let(:receiver_class) { FakeRecordClass }

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
      Assert.stub(subject, :destroy) { false }
    end

    let(:receiver_class) { FakeRecordClass }

    should "raise ActiveRecord::RecordNotDestroyed" do
      assert_that(-> { subject.destroy! })
        .raises(ActiveRecord::RecordNotDestroyed)
    end
  end

  require "active_record"

  class FakeRecordBaseClass
    # Include ActiveRecord::Persistence to test the `destroy!` logic
    # (the `_raise_record_not_destroyed` method) that we had to re-implement in
    # the MuchRails::Records::ValidateDestroy.
    include ActiveRecord::Persistence

    attr_accessor :super_destroy_called

    attr_accessor :destruction_errors_exist

    def destroy
      @super_destroy_called = true
    end
  end

  class FakeRecordClass < FakeRecordBaseClass
    include MuchRails::Records::ValidateDestroy

    def validate_destroy
      if destruction_errors_exist
        destruction_error_messages << "TEST DESTRUCTION ERROR1"
        destruction_error_messages << "TEST DESTRUCTION ERROR2"
      end
    end
  end

  class FakeRecordMissingValidateDestroyClass < FakeRecordBaseClass
    include MuchRails::Records::ValidateDestroy

  end
end
