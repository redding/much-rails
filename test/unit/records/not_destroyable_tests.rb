# frozen_string_literal: true

require "assert"
require "much-rails/records/not_destroyable"

module MuchRails::Records::NotDestroyable
  class UnitTests < Assert::Context
    desc "MuchRails::Records::NotDestroyable"
    subject { unit_class }

    let(:unit_class) { MuchRails::Records::NotDestroyable }

    should "include MuchRails::Plugin" do
      assert_that(subject).includes(MuchRails::Plugin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject { receiver_class.new }

    let(:receiver_class) {
      Class.new do
        include MuchRails::Records::NotDestroyable
      end
    }

    should "disable destroying a record" do
      assert_that(subject.destruction_error_messages)
        .equals(["#{subject.class.name} records can't be deleted."])

      assert_that(subject.destroy).is_false

      assert_that(-> { subject.destroy! })
        .raises(MuchRails::Records::ValidateDestroy::DestructionInvalid)

      assert_that(subject.destroyable?).is_false
    end
  end
end
