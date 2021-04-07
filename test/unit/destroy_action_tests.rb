# frozen_string_literal: true

require "assert"
require "much-rails/destroy_action"

module MuchRails::DestroyAction
  class UnitTests < Assert::Context
    desc "MuchRails::DestroyAction"
    subject{ unit_class }

    let(:unit_class){ MuchRails::DestroyAction }

    should "include MuchRails::Mixin" do
      assert_that(subject).includes(MuchRails::Mixin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject{ receiver_class }

    setup do
      Assert.stub_on_call(receiver_class, :change_result) do |call|
        @change_action_class_change_result_call = call
      end
    end

    let(:receiver_class) do
      Class.new do
        include MuchRails::DestroyAction

        destroy_result{ MuchRails::Result.success }

        on_call{}
      end
    end

    should have_imeths :destroy_result

    should "be configured as expected" do
      assert_that(subject).includes(MuchRails::ChangeAction)
    end

    should "call .change_result for its .destroy_result method" do
      subject.destroy_result

      assert_that(@change_action_class_change_result_call).is_not_nil
    end
  end

  class InitTests < ReceiverTests
    desc "when init"
    subject do
      receiver_class.new(
        params: {},
        current_session: nil,
        request: nil,
      )
    end

    should have_imeths :destroy_result

    should "call #change_result for its #destroy_result method" do
      Assert.stub_on_call(subject, :change_result) do |call|
        @change_action_instance_change_result_call = call
      end

      subject.destroy_result
      assert_that(@change_action_instance_change_result_call).is_not_nil
    end

    should "raise a custom error message if no destroy result block defined" do
      Assert.stub(
        receiver_class.much_rails_change_action_config,
        :change_result_block,
      ){ nil }

      exception = assert_that{ subject.destroy_result }.raises
      assert_that(exception.message)
        .equals("A `destroy_result` block must be defined.")
    end
  end
end
