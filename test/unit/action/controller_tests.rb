# frozen_string_literal: true

require "assert"
require "much-rails/action/controller"

require "test/support/actions/show"
require "test/support/fake_action_controller"

module MuchRails::Action::Controller
  class UnitTests < Assert::Context
    desc "MuchRails::Action::Controller"
    subject{ unit_module }

    let(:unit_module){ MuchRails::Action::Controller }

    should "include MuchRails::Mixin" do
      assert_that(subject).includes(MuchRails::Mixin)
    end

    should "know its constants" do
      assert_that(subject::DEFAULT_ACTION_CLASS_FORMAT).equals(:any)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject{ receiver_class }

    let(:receiver_class) do
      Class.new{ include FakeActionController }
    end
  end

  class ReceiverInitTests < ReceiverTests
    desc "when init"
    subject{ receiver_class.new(params1) }

    setup do
      Assert.stub(::Actions::Show, :format){ nil }
    end

    let(:params1) do
      {
        MuchRails::Action::Router::ACTION_CLASS_PARAM_NAME => "Actions::Show",
        controller: "actions",
        action: "show",
        nested: {
          value: "VALUE 1",
        },
      }
    end

    should have_readers :much_rails_action_class

    should have_imeths(
      MuchRails::Action::Router::CONTROLLER_CALL_ACTION_METHOD_NAME,
    )
    should have_imeths(
      MuchRails::Action::Router::CONTROLLER_NOT_FOUND_METHOD_NAME,
    )
    should have_imeths :much_rails_action_class_name
    should have_imeths :much_rails_action_class_format
    should have_imeths :much_rails_action_params
    should have_imeths :require_much_rails_action_class
    should have_imeths :permit_all_much_rails_action_params

    should "know its attributes" do
      assert_that(subject.much_rails_action_class_name)
        .equals("::Actions::Show")

      assert_that(subject.much_rails_action_class_format)
        .equals(unit_module::DEFAULT_ACTION_CLASS_FORMAT)

      assert_that(subject.much_rails_action_params)
        .equals(
          nested: { value: "VALUE 1" },
          value: "VALUE 1",
        )

      assert_that(subject.much_rails_action_class).equals(Actions::Show)

      Assert.stub(::Actions::Show, :format){ :html }
      receiver = receiver_class.new(params1)
      assert_that(receiver.much_rails_action_class_format).equals(:html)
    end
  end

  class ReceiverInitWithUnknownActionClassTests < ReceiverTests
    desc "when init with an unknown action class"
    subject{ receiver_class.new(params1) }

    let(:params1) do
      {
        MuchRails::Action::Router::ACTION_CLASS_PARAM_NAME =>
          "Actions::Unknown",
      }
    end

    should "return not found when not raising response exceptions" do
      Assert.stub(MuchRails.config.action, :raise_response_exceptions?){ false }

      assert_that(subject.much_rails_action_class).is_nil
      assert_that(subject.head_called_with).equals([:not_found])
    end

    should "raise an exception when raising response exceptions" do
      Assert.stub(MuchRails.config.action, :raise_response_exceptions?){ true }

      assert_that{ subject.much_rails_action_class }
        .raises(MuchRails::Action::ActionError)
    end
  end
end
