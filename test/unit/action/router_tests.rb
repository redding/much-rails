require "assert"
require "much-rails/action/router"

class MuchRails::Action::Router
  class UnitTests < Assert::Context
    desc "MuchRails::Action::Router"
    subject { unit_class }

    let(:unit_class) { MuchRails::Action::Router }

    should have_imeths :url_class

    should "be a BaseRouter" do
      assert_that(subject < MuchRails::Action::BaseRouter).is_true
    end

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

    let(:controller_name1) { Factory.string }

    should have_readers :controller_name, :draw

    should "know its attributes" do
      assert_that(subject.controller_name)
        .equals(unit_class::DEFAULT_CONTROLLER_NAME)

      router = unit_class.new(controller_name: controller_name1)
      assert_that(router.controller_name).equals(controller_name1)
    end

    should "draw Rails Application routes" do
      request_type_name = Factory.symbol
      request_type_proc = ->(request) {}
      subject.request_type(request_type_name, &request_type_proc)
      request_type_class_name = Factory.string
      path = Factory.url
      url_name = Factory.symbol
      url_path = Factory.url
      url = subject.url(url_name, url_path)
      default_class_name = Factory.string

      subject.get(
        url_name,
        default_class_name,
        request_type_name => request_type_class_name
      )
      subject.post(url_name, default_class_name)
      subject.put(url_path, default_class_name)
      subject.patch(url_name, default_class_name)
      subject.delete(url_name, default_class_name)

      application_routes = FakeApplicationRoutes.new
      subject.draw(application_routes)

      expected_draw_route_to =
        "#{subject.controller_name}##{unit_class::CONTROLLER_METHOD_NAME}"
      expected_default_defaults =
        { unit_class::ACTION_CLASS_PARAM_NAME => default_class_name }

      assert_that(application_routes.get_calls.size).equals(2)
      assert_that(application_routes.get_calls.first.pargs).equals([url_path])
      assert_that(application_routes.get_calls.first.kargs)
        .equals(
          to: expected_draw_route_to,
          as: url_name,
          defaults:
            { unit_class::ACTION_CLASS_PARAM_NAME => request_type_class_name },
          constraints: request_type_proc,
        )
      assert_that(application_routes.get_calls.last.pargs).equals([url_path])
      assert_that(application_routes.get_calls.last.kargs)
        .equals(
          to: expected_draw_route_to,
          as: url_name,
          defaults: expected_default_defaults,
        )

      assert_that(application_routes.post_calls.size).equals(1)
      assert_that(application_routes.post_calls.last.pargs).equals([url_path])
      assert_that(application_routes.post_calls.last.kargs)
        .equals(
          to: expected_draw_route_to,
          as: url_name,
          defaults: expected_default_defaults,
        )

      assert_that(application_routes.put_calls.size).equals(1)
      assert_that(application_routes.put_calls.last.pargs).equals([url_path])
      assert_that(application_routes.put_calls.last.kargs)
        .equals(
          to: expected_draw_route_to,
          as: nil,
          defaults: expected_default_defaults,
        )

      assert_that(application_routes.patch_calls.size).equals(1)
      assert_that(application_routes.patch_calls.last.pargs).equals([url_path])
      assert_that(application_routes.patch_calls.last.kargs)
        .equals(
          to: expected_draw_route_to,
          as: url_name,
          defaults: expected_default_defaults,
        )

      assert_that(application_routes.delete_calls.size).equals(1)
      assert_that(application_routes.delete_calls.last.pargs).equals([url_path])
      assert_that(application_routes.delete_calls.last.kargs)
        .equals(
          to: expected_draw_route_to,
          as: url_name,
          defaults: expected_default_defaults,
        )
    end
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

  class FakeApplicationRoutes
    attr_reader :get_calls, :post_calls,:put_calls, :patch_calls, :delete_calls

    def initialize
      @get_calls    = []
      @post_calls   = []
      @put_calls    = []
      @patch_calls  = []
      @delete_calls = []
    end

    def get(*args)
      @get_calls << MuchStub::Call.new(*args)
    end

    def post(*args)
      @post_calls << MuchStub::Call.new(*args)
    end

    def put(*args)
      @put_calls << MuchStub::Call.new(*args)
    end

    def patch(*args)
      @patch_calls << MuchStub::Call.new(*args)
    end

    def delete(*args)
      @delete_calls << MuchStub::Call.new(*args)
    end
  end
end
