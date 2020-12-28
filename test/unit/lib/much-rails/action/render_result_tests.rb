require "assert"
require "much-rails/action/render_result"

class MuchRails::Action::RenderResult
  class UnitTests < Assert::Context
    desc "MuchRails::Action::RenderResult"
    subject { unit_class }

    let(:unit_class) { MuchRails::Action::RenderResult }
  end

  class InitTests < UnitTests
    desc "when init"
    subject { unit_class.new(view_model1, **render_kargs1) }

    let(:controller1) { FakeController.new }
    let(:view_model1) { Object.new }
    let(:render_kargs1) {
      { something: "TEST_VALUE" }
    }

    should have_readers :render_view_model, :render_kargs

    should "know its attributes" do
      assert_that(subject.render_view_model).equals(view_model1)
      assert_that(subject.render_kargs).equals(render_kargs1)

      controller1.instance_exec(subject, &subject.execute_block)
      assert_that(controller1.view_model).equals(view_model1)
      assert_that(controller1.render_called_with).equals(render_kargs1)
    end
  end

  class FakeController
    attr_reader :view_model, :render_called_with

    def render(**kargs)
      @render_called_with = kargs
    end
  end
end
