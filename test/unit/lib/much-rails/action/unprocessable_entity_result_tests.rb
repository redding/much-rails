require "assert"
require "much-rails/action/unprocessable_entity_result"

class MuchRails::Action::UnprocessableEntityResult
  class UnitTests < Assert::Context
    desc "MuchRails::Action::UnprocessableEntityResult"
    subject { unit_class }

    let(:unit_class) { MuchRails::Action::UnprocessableEntityResult }
  end

  class InitTests < UnitTests
    desc "when init"
    subject { unit_class.new(errors1) }

    let(:controller1) { FakeController.new }
    let(:errors1) {
      { something: "ERROR" }
    }

    should have_readers :errors

    should "know its attributes" do
      assert_that(subject.errors).equals(errors1)

      controller1.instance_exec(subject, &subject.execute_block)
      assert_that(controller1.render_called_with)
        .equals(
          json: "ERRORS JSON",
          status: :unprocessable_entity
        )
      assert_that(controller1.action_errors_json_called_with)
        .equals(something: "ERROR")
    end
  end

  class FakeController
    attr_reader :render_called_with, :action_errors_json_called_with

    def render(**kargs)
      @render_called_with = kargs
    end

    private

    def action_errors_json(errors)
      @action_errors_json_called_with = errors
      "ERRORS JSON"
    end
  end
end
