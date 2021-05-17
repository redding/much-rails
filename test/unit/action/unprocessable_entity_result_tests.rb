# frozen_string_literal: true

require "assert"
require "much-rails/action/unprocessable_entity_result"

require "test/support/fake_action_controller"

class MuchRails::Action::UnprocessableEntityResult
  class UnitTests < Assert::Context
    desc "MuchRails::Action::UnprocessableEntityResult"
    subject{ unit_class }

    let(:unit_class){ MuchRails::Action::UnprocessableEntityResult }
  end

  class InitTests < UnitTests
    desc "when init"
    subject{ unit_class.new(errors1) }

    let(:controller1){ FakeController.new(params1) }
    let(:params1) do
      {
        MuchRails::Action::Router.ACTION_CLASS_PARAM_NAME => "Actions::Show",
      }
    end
    let(:errors1) do
      { field: "ERROR 1" }
    end

    should have_readers :errors

    should "know its attributes" do
      assert_that(subject.errors).equals(errors1)

      controller1.instance_exec(subject, &subject.execute_block)
      assert_that(controller1.render_called_with)
        .equals(
          json:
            {
              field: "ERROR 1",
              "nested[field]" => "ERROR 1",
            },
          status: :unprocessable_entity,
        )
    end
  end

  class FakeController
    include FakeActionController
  end
end
