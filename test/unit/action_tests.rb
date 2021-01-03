require "assert"
require "much-rails/action"

module MuchRails::Action
  class UnitTests < Assert::Context
    desc "MuchRails::Action"
    subject { unit_class }

    let(:unit_class) { MuchRails::Action }

    should "include MuchRails::Plugin" do
      assert_that(subject).includes(MuchRails::Plugin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject { receiver_class }

    setup do
      Assert.stub(MuchRails.config.action, :namespace) { "Actions::" }
      Assert.stub(receiver_class, :to_s) {
        "#{MuchRails.config.action.namespace}Some::Namespace::For::"\
        "#{MuchRails.config.action.namespace}Thing::Show"
      }
    end

    let(:receiver_class) {
      Class.new do
        include MuchRails::Action
      end
    }

    let(:block1) { -> {} }
    let(:block2) { -> {} }

    should have_imeths :action_error_class, :params_root, :required_params
    should have_imeths :date_params, :time_params, :boolean_params, :format
    should have_imeths :on_validation, :on_validation_blocks
    should have_imeths :on_call, :on_call_block
    should have_imeths :on_before_call, :on_before_call_blocks
    should have_imeths :on_after_call, :on_after_call_blocks

    should "be configured as expected" do
      assert_that(subject).includes(MuchRails::Config)
      assert_that(subject).includes(MuchRails::WrapAndCallMethod)

      assert_that(subject.much_rails_action_config)
        .is_instance_of(MuchRails::Action::MuchRailsActionConfig)
    end

    should "know its atributes" do
      # action_error_class
      assert_that(subject.action_error_class).is(MuchRails::Action::ActionError)

      # params_root
      assert_that { subject.params_root("ROOT VALUE1", "ROOT VALUE2") }
        .changes(
          "subject.much_rails_action_config.params_root.dup",
          from: nil,
          to: ["ROOT VALUE1", "ROOT VALUE2"]
        )
      assert_that(subject.params_root).equals(["ROOT VALUE1", "ROOT VALUE2"])

      # required_params
      assert_that { subject.required_params(:test_param, :other_param) }
        .changes(
          "subject.much_rails_action_config.required_params.dup",
          from: [],
          to: [:test_param, :other_param]
        )
      assert_that(subject.required_params).equals([:test_param, :other_param])

      # date_params
      assert_that { subject.date_params(:test_param, :other_param) }
        .changes(
          "subject.much_rails_action_config.date_params.dup",
          from: [],
          to: [:test_param, :other_param]
        )
      assert_that(subject.date_params).equals([:test_param, :other_param])

      # time_params
      assert_that { subject.time_params(:test_param, :other_param) }
        .changes(
          "subject.much_rails_action_config.time_params.dup",
          from: [],
          to: [:test_param, :other_param]
        )
      assert_that(subject.time_params).equals([:test_param, :other_param])

      # boolean_params
      assert_that { subject.boolean_params(:test_param, :other_param) }
        .changes(
          "subject.much_rails_action_config.boolean_params.dup",
          from: [],
          to: [:test_param, :other_param]
        )
      assert_that(subject.boolean_params).equals([:test_param, :other_param])

      # format
      assert_that { subject.format("VALUE") }
        .changes(
          "subject.much_rails_action_config.format.dup",
          from: nil,
          to: "VALUE"
        )
      assert_that(subject.format).equals("VALUE")

      # on_validation
      assert_that { subject.on_validation(&block1) }
        .changes(
          "subject.much_rails_action_config.on_validation_blocks.dup",
          from: [],
          to: [block1]
        )

      # on_validation_blocks
      assert_that { subject.on_validation(&block2) }
        .changes(
          "subject.on_validation_blocks.dup",
          from: [block1],
          to: [block1, block2]
        )

      # on_call, on_call_block
      subject.on_call(&block1)
      assert_that(subject.much_rails_action_config.on_call_block)
        .equals(block1)
      assert_that(subject.on_call_block).equals(block1)

      # on_before_call
      assert_that { subject.on_before_call(&block1) }
        .changes(
          "subject.much_rails_action_config.on_before_call_blocks.dup",
          from: [],
          to: [block1]
        )

      # on_before_call_blocks
      assert_that { subject.on_before_call(&block2) }
        .changes(
          "subject.on_before_call_blocks.dup",
          from: [block1],
          to: [block1, block2]
        )

      # on_after_call
      assert_that { subject.on_after_call(&block1) }
        .changes(
          "subject.much_rails_action_config.on_after_call_blocks.dup",
          from: [],
          to: [block1]
        )

      # on_after_call_blocks
      assert_that { subject.on_after_call(&block2) }
        .changes(
          "subject.on_after_call_blocks.dup",
          from: [block1],
          to: [block1, block2]
        )

      # default_action_template_name
      assert_that(subject.default_action_template_name)
        .equals(
          "some/namespace/for/"\
          "#{MuchRails.config.action.namespace.tableize.singularize}"\
          "thing/show"
        )
    end
  end

  class InitTests < ReceiverTests
    desc "when init"
    subject {
      receiver_class.new(
        params: params1,
        current_user: current_user1,
        request: request1,
      )
    }

    let(:receiver_class) {
      Class.new do
        include MuchRails::Action

        attr_reader :before_call_called, :after_call_called, :call_called

        params_root :some_root_param
        required_params :name
        date_params :entered_on
        time_params :updated_at
        boolean_params :active

        format :json

        on_validation do
          if params[:validate_other_param] && params[:other_param].blank?
            add_required_param_error(:other_param)
          end

          if params[:fail_custom_validation]
            errors[:custom_validation] << "ERROR1"
          end
        end

        on_before_call do
          @before_call_called = true
        end

        on_call do
          @call_called = true
        end

        on_after_call do
          @after_call_called = true
        end
      end
    }

    let(:current_date) { Date.current }
    let(:current_time) { Time.current }
    let(:date1) { current_date }
    let(:time1) { current_time.utc }

    let(:params1) {
      {
        name: "NAME",
        entered_on: current_date,
        updated_at: current_time.utc,
        active: "true",
      }
    }
    let(:current_user1) { "CURRENT USER 1"}
    let(:request1) { "REQUEST 1"}

    should have_readers :params, :current_user, :request, :errors
    should have_imeths :on_call, :valid_action?, :successful_action?

    should "know its attributes" do
      assert_that(subject.params).equals(params1.with_indifferent_access)
      assert_that(subject.current_user).equals(current_user1)
      assert_that(subject.request).equals(request1)
    end

    should "return the expected Result" do
      result = subject.call
      assert_that(result.head_args).equals([:ok])

      assert_that(subject.before_call_called).is_true
      assert_that(subject.call_called).is_true
      assert_that(subject.after_call_called).is_true

      assert_that(subject.entered_on).equals(date1)
      assert_that(subject.updated_at.iso8601).equals(time1.iso8601)
      assert_that(subject.active?).is_true
    end

    should "return the expected Result when halted in an on_validation block" do
      receiver_class.on_validation { halt }
      result = subject.call
      assert_that(result.head_args).equals([:ok])

      assert_that(subject.before_call_called).is_nil
      assert_that(subject.call_called).is_nil
      assert_that(subject.after_call_called).is_nil
    end

    should "return the expected Result "\
           "when halted in an on_before_call block" do
      receiver_class.on_before_call { halt }
      result = subject.call
      assert_that(result.head_args).equals([:ok])

      assert_that(subject.before_call_called).is_true
      assert_that(subject.call_called).is_nil
      assert_that(subject.after_call_called).is_nil
    end

    should "return the expected Result when halted in the on_call block" do
      receiver_class.on_call { halt }
      result = subject.call
      assert_that(result.head_args).equals([:ok])

      assert_that(subject.before_call_called).is_true
      assert_that(subject.call_called).is_nil
      assert_that(subject.after_call_called).is_true
    end

    should "return the expected Result when halted in an on_after_call block" do
      receiver_class.on_after_call { halt }
      result = subject.call
      assert_that(result.head_args).equals([:ok])

      assert_that(subject.before_call_called).is_true
      assert_that(subject.call_called).is_true
      assert_that(subject.after_call_called).is_true
    end

    should "return the expected Result given an on_call block that renders" do
      view_model = Object.new
      receiver_class.on_call { render(view_model) }
      result = subject.call
      assert_that(result.render_view_model).is(view_model)
      assert_that(result.render_kargs)
        .equals(template: subject.class.default_action_template_name)

      receiver_class.on_call { render("some/view/template", layout: false) }
      action = receiver_class.new(params: params1)
      result = action.call
      assert_that(result.render_view_model).is_nil
      assert_that(result.render_kargs)
        .equals(
          template: "some/view/template",
          layout: false,
        )

      receiver_class.on_call {
        render(view_model, "some/view/template", layout: false)
      }
      action = receiver_class.new(params: params1)
      result = action.call
      assert_that(result.render_view_model).is(view_model)
      assert_that(result.render_kargs)
        .equals(
          template: "some/view/template",
          layout: false,
        )

      receiver_class.on_call {
        render(view_model, "some/view/template", template: "other/template")
      }
      action = receiver_class.new(params: params1)
      result = action.call
      assert_that(result.render_view_model).is(view_model)
      assert_that(result.render_kargs).equals(template: "other/template")

      receiver_class.on_call { render(view_model, template: "other/template") }
      action = receiver_class.new(params: params1)
      result = action.call
      assert_that(result.render_view_model).is(view_model)
      assert_that(result.render_kargs).equals(template: "other/template")
    end

    should "return the expected Result given an on_call block that redirects" do
      receiver_class.on_call { redirect_to("URL") }
      result = subject.call
      assert_that(result.redirect_to_args).equals(["URL"])
    end

    should "return the expected Result "\
           "given an on_call block that responds with a header" do
      receiver_class.on_call { head(:not_found) }
      result = subject.call
      assert_that(result.head_args).equals([:not_found])
    end

    should "return the expected Result "\
           "given an on_call block that sends a file" do
      receiver_class.on_call { send_file("FILE") }
      result = subject.call
      assert_that(result.send_file_args).equals(["FILE"])
    end

    should "return the expected Result "\
           "given an on_call block that sends data" do
      receiver_class.on_call { send_data("DATA") }
      result = subject.call
      assert_that(result.send_data_args).equals(["DATA"])
    end

    should "return the expected Result given invalid params" do
      Assert.stub(subject, :valid_action?) { false }
      result = subject.call
      assert_that(result.errors).equals(subject.errors)

      params1.delete(:name)
      result = receiver_class.new(params: params1).call
      assert_that(result.errors[:name]).includes("can't be blank")

      params1[:entered_on] = "INVALID DATE"
      result = receiver_class.new(params: params1).call
      assert_that(result.errors[:entered_on]).includes("invalid date")

      params1[:updated_at] = "INVALID TIME"
      result = receiver_class.new(params: params1).call
      assert_that(result.errors[:updated_at]).includes("invalid time")

      params1[:validate_other_param] = true
      params1[:other_param] = [nil, ""].sample
      params1[:fail_custom_validation] = true
      result = receiver_class.new(params: params1).call
      assert_that(result.errors[:other_param]).includes("can't be blank")
      assert_that(result.errors[:custom_validation]).includes("ERROR1")
    end
  end
end
