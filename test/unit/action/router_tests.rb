require "assert"
require "much-rails/action/router"

class MuchRails::Action::Router
  class UnitTests < Assert::Context
    desc "MuchRails::Action::Router"
    subject { unit_class }

    let(:unit_class) { MuchRails::Action::Router }

    should have_imeths :url_class

    should "know its constants" do
      assert_that(subject::DEFAULT_CONTROLLER_NAME).equals("application")
      assert_that(subject::CONTROLLER_METHOD_NAME)
        .equals(:much_rails_call_action)
      assert_that(subject::ACTION_CLASS_PARAM_NAME)
        .equals(:much_rails_action_class_name)
      assert_that(subject.url_class).equals(unit_class::URL)
    end
  end

  class InitTests < UnitTests
    desc "when init"
    subject { unit_class.new }
  end

  class URLUnitTests < UnitTests
    desc "URL"
    subject { url_class }

    let(:url_class) { unit_class::URL }
  end

  class URLInitTests < URLUnitTests
    desc "when init"
    subject { url_class.new(router1, url_path1, url_name1) }

    setup do
      Assert.stub_on_call(MuchRails::RailsRoutes, :method_missing) { |call|
        @rails_routes_method_missing_call = call
        "TEST PATH OR URL STRING"
      }
    end

    let(:url_name1) { Factory.symbol }
    let(:url_path1) { Factory.url }
    let(:router1) { unit_class.new }

    should have_imeths :path_for, :url_for

    should "know its attributes" do
      path_string = subject.path_for("TEST PATH ARGS")
      assert_that(path_string).equals("TEST PATH OR URL STRING")
      assert_that(@rails_routes_method_missing_call.args)
        .equals(["#{url_name1}_path".to_sym, "TEST PATH ARGS"])

      url_string = subject.url_for("TEST URL ARGS")
      assert_that(url_string).equals("TEST PATH OR URL STRING")
      assert_that(@rails_routes_method_missing_call.args)
        .equals(["#{url_name1}_url".to_sym, "TEST URL ARGS"])
    end
  end
end
