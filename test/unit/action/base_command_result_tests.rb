require "assert"
require "much-rails/action/base_command_result"

class MuchRails::Action::BaseCommandResult
  class UnitTests < Assert::Context
    desc "MuchRails::Action::BaseCommandResult"
    subject { unit_class }

    let(:unit_class) { MuchRails::Action::BaseCommandResult }
  end

  class InitTests < UnitTests
    desc "when init"
    subject {
      unit_class.new(
        :do_something,
        "VALUE",
        other_value: "OTHER VALUE"
      )
    }

    let(:controller1) { FakeController.new }

    should have_readers :command_name, :command_args

    should "know its attributes" do
      assert_that(subject.command_name).equals(:do_something)
      assert_that(subject.command_args)
        .equals(["VALUE", other_value: "OTHER VALUE"])

      assert_that(controller1.instance_exec(subject, &subject.execute_block))
        .equals(value: "VALUE", other_value: "OTHER VALUE")
    end
  end

  class FakeController
    def do_something(value, other_value:)
      { value: value, other_value: other_value }
    end
  end
end
