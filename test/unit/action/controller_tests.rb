require "assert"
require "much-rails/action/controller"

require "test/support/actions/show"
require "test/support/fake_action_controller"

module MuchRails::Action::Controller
  class UnitTests < Assert::Context
    desc "MuchRails::Action::Controller"
    subject { unit_module }

    let(:unit_module) { MuchRails::Action::Controller }

    should "include MuchRails::Plugin" do
      assert_that(subject).includes(MuchRails::Plugin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject { receiver_class }

    let(:receiver_class) {
      Class.new { include FakeActionController }
    }
  end

  class ReceiverInitTests < ReceiverTests
    desc "when init"
    subject { receiver_class.new(params1) }

    let(:params1) {
      {
        MuchRails::Action::Router::ACTION_CLASS_PARAM_NAME => "Actions::Show",
        controller: "actions",
        action: "show",
        nested: {
          value: "VALUE 1"
        },
      }
    }

    should have_readers :much_rails_action_class

    should have_imeths MuchRails::Action::Router::CONTROLLER_METHOD_NAME
    should have_imeths :much_rails_action_class_name
    should have_imeths :much_rails_action_params
    should have_imeths :require_much_rails_action_class
    should have_imeths :permit_all_much_rails_action_params

    should "know its attributes" do
      assert_that(subject.much_rails_action_class_name)
        .equals("::Actions::Show")

      assert_that(subject.much_rails_action_params)
        .equals(
          nested: { value: "VALUE 1" },
          value: "VALUE 1",
        )

      assert_that(subject.much_rails_action_class).equals(Actions::Show)
    end
  end

  class ReceiverInitWithUnknownActionClassTests < ReceiverTests
    desc "when init with an unknown action class"
    subject { receiver_class.new(params1) }

    let(:params1) {
      {
        MuchRails::Action::Router::ACTION_CLASS_PARAM_NAME => "Actions::Unknown",
      }
    }

    should "return not found when not raising response exceptions" do
      Assert.stub(MuchRails.config.action, :raise_response_exceptions?) { false }

      assert_that(subject.much_rails_action_class).is_nil
      assert_that(subject.head_called_with).equals([:not_found])
    end

    should "raise an exception when raising response exceptions" do
      Assert.stub(MuchRails.config.action, :raise_response_exceptions?) { true }

      assert_that { subject.much_rails_action_class }
        .raises(MuchRails::Action::ActionError)
    end
  end

  class FakeController
    def self.before_action(method_name)
      before_actions << method_name
    end

    def self.before_actions
      @before_actions ||= []
    end

    attr_reader :params, :head_called_with

    def initialize(params)
      @params = FakeParams.new(params)
      self.class.before_actions.each do |before_action|
        self.public_send(before_action)
      end
    end

    def head(*args)
      @head_called_with = args
      self
    end
  end

  class FakeParams
    def initialize(params)
      @params = params
    end

    def permit!
      @permit_called = true
      self
    end

    def [](key)
      @params[key]
    end

    def to_h
      raise "params haven't been permitted" unless @permit_called
      @params
    end
  end
end
