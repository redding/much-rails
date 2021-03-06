# frozen_string_literal: true

require "assert"
require "much-rails/records/always_destroyable"

module MuchRails::Records::AlwaysDestroyable
  class UnitTests < Assert::Context
    desc "MuchRails::Records::AlwaysDestroyable"
    subject{ unit_class }

    let(:unit_class){ MuchRails::Records::AlwaysDestroyable }

    should "include MuchRails::Mixin" do
      assert_that(subject).includes(MuchRails::Mixin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject{ receiver_class.new }

    let(:receiver_class) do
      Class.new do
        def destroy(*)
          true
        end

        include MuchRails::Records::AlwaysDestroyable
      end
    end

    should "enable destroying a record" do
      assert_that(subject.destruction_error_messages).equals([])

      assert_that(subject.destroy).is_true

      # won't raise MuchRails::Records::DestructionInvalid
      subject.destroy!

      assert_that(subject.destroyable?).is_true
    end
  end
end
