# frozen_string_literal: true

require "assert"
require "much-rails/save_action"

module MuchRails::SaveAction
  class UnitTests < Assert::Context
    desc "MuchRails::SaveAction"
    subject { unit_class }

    let(:unit_class) { MuchRails::SaveAction }

    should "include MuchRails::Plugin" do
      assert_that(subject).includes(MuchRails::Plugin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject { receiver_class }

    setup do
      Assert.stub_on_call(receiver_class, :change_result) { |call|
        @change_action_class_change_result_call = call
      }
    end

    let(:receiver_class) {
      Class.new do
        include MuchRails::SaveAction

        save_result { MuchRails::Result.success  }

        on_call {}
      end
    }

    should have_imeths :save_result

    should "be configured as expected" do
      assert_that(subject).includes(MuchRails::ChangeAction)
    end

    should "call .change_result for its .save_result method" do
      subject.save_result

      assert_that(@change_action_class_change_result_call).is_not_nil
    end
  end

  class InitTests < ReceiverTests
    desc "when init"
    subject {
      receiver_class.new(
        params: {},
        current_user: nil,
        request: nil,
      )
    }

    should have_imeths :save_result

    should "call #change_result for its #save_result method" do
      Assert.stub_on_call(subject, :change_result) { |call|
        @change_action_instance_change_result_call = call
      }

      subject.save_result
      assert_that(@change_action_instance_change_result_call).is_not_nil
    end

    should "raise a custom error message if no save result block is defined" do
      Assert.stub(
        receiver_class.much_rails_change_action_config,
        :change_result_block
      ) { nil }

      exception = assert_that { subject.save_result }.raises
      assert_that(exception.message)
        .equals("A `save_result` block must be defined.")
    end
  end
end
