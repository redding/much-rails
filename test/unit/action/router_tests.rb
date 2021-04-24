# frozen_string_literal: true

require "assert"
require "much-rails/action/router"

require "much-rails/rails_routes"

class MuchRails::Action::Router
  class UnitTests < Assert::Context
    desc "MuchRails::Action::Router"
    subject{ unit_class }

    let(:unit_class){ MuchRails::Action::Router }

    let(:caller1){ ["TEST CALLER 1"] }

    should have_imeths :url_class

    should "be a BaseRouter" do
      assert_that(subject < MuchRails::Action::BaseRouter).is_true
    end

    should "know its constants" do
      assert_that(subject::DEFAULT_CONTROLLER_NAME).equals("application")
      assert_that(subject::CONTROLLER_CALL_ACTION_METHOD_NAME)
        .equals(:much_rails_call_action)
      assert_that(subject::CONTROLLER_NOT_FOUND_METHOD_NAME)
        .equals(:much_rails_not_found)
      assert_that(subject::ACTION_CLASS_PARAM_NAME)
        .equals(:much_rails_action_class_name)
      assert_that(subject.url_class).equals(unit_class::URL)
    end
  end

  class LoadTests < UnitTests
    desc ".load"

    setup do
      Assert.stub(::Rails, :root){ Pathname.new(TEST_SUPPORT_PATH) }
    end

    should "eval the named routes file" do
      router = unit_class.load(:test)
      assert_that(router.url_set).is_not_empty
      assert_that(router.url_set.fetch(:root).path).equals("/")
    end

    should "complain if no file name given" do
      assert_that{ unit_class.load([nil, "", "  "]) }.raises(ArgumentError)
    end

    should "complain if the named routes file can't be found" do
      assert_that{ unit_class.load(:unknown) }.raises(ArgumentError)
    end
  end

  class InitTests < UnitTests
    desc "when init"
    subject{ unit_class.new }

    let(:controller_name1){ Factory.string }

    should have_readers :controller_name, :draw

    should "know its attributes" do
      assert_that(subject.controller_name)
        .equals(unit_class::DEFAULT_CONTROLLER_NAME)

      router = unit_class.new(controller_name: controller_name1)
      assert_that(router.controller_name).equals(controller_name1)
    end

    should "draw Rails Application routes" do
      request_type_name = Factory.symbol
      request_type_proc = ->(request){}
      subject.request_type(request_type_name, &request_type_proc)
      request_type_class_name = "Actions::Show"
      url_name = Factory.symbol
      url_path = Factory.url
      subject.url(url_name, url_path)
      default_class_name = "Actions::Show"

      subject.get(
        url_name,
        default_class_name,
        request_type_name => request_type_class_name,
      )
      subject.post(url_name, default_class_name)
      subject.put(url_path, default_class_name)
      subject.patch(url_name, default_class_name)
      subject.delete(url_name, default_class_name)

      url2_name = Factory.symbol
      url2_path = Factory.url
      subject.url(url2_name, url2_path)

      application_routes = FakeApplicationRoutes.new
      subject.draw(application_routes)

      expected_draw_url_to =
        "#{subject.controller_name}"\
        "##{unit_class::CONTROLLER_NOT_FOUND_METHOD_NAME}"
      expected_draw_route_to =
        "#{subject.controller_name}"\
        "##{unit_class::CONTROLLER_CALL_ACTION_METHOD_NAME}"
      expected_default_defaults =
        {
          unit_class::ACTION_CLASS_PARAM_NAME => default_class_name,
          "format" => :html,
        }

      assert_that(application_routes.get_calls.size).equals(3)
      assert_that(application_routes.get_calls[0].pargs).equals([url_path])
      assert_that(application_routes.get_calls[0].kargs)
        .equals(
          to: expected_draw_route_to,
          as: url_name,
          defaults:
            {
              unit_class::ACTION_CLASS_PARAM_NAME => request_type_class_name,
              "format" => :html,
            },
          constraints: request_type_proc,
        )
      assert_that(application_routes.get_calls[1].pargs).equals([url_path])
      assert_that(application_routes.get_calls[1].kargs)
        .equals(
          to: expected_draw_route_to,
          as: nil,
          defaults: expected_default_defaults,
        )
      assert_that(application_routes.get_calls[2].pargs).equals([url2_path])
      assert_that(application_routes.get_calls[2].kargs)
        .equals(
          to: expected_draw_url_to,
          as: url2_name,
        )

      assert_that(application_routes.post_calls.size).equals(1)
      assert_that(application_routes.post_calls.last.pargs).equals([url_path])
      assert_that(application_routes.post_calls.last.kargs)
        .equals(
          to: expected_draw_route_to,
          as: nil,
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
          as: nil,
          defaults: expected_default_defaults,
        )

      assert_that(application_routes.delete_calls.size).equals(1)
      assert_that(application_routes.delete_calls.last.pargs).equals([url_path])
      assert_that(application_routes.delete_calls.last.kargs)
        .equals(
          to: expected_draw_route_to,
          as: nil,
          defaults: expected_default_defaults,
        )
    end

    should "complain when drawing a route with an unknown Action class" do
      action_class_name = "Unknown::Action"
      subject.get(Factory.url, action_class_name, called_from: caller1)
      application_routes = FakeApplicationRoutes.new

      exception =
        assert_that{ subject.draw(application_routes) }.raises(NameError)
      assert_that(exception.backtrace).equals(caller1)
    end
  end

  class URLUnitTests < UnitTests
    desc "URL"
    subject{ url_class }

    let(:url_class){ unit_class::URL }
  end

  class URLInitTests < URLUnitTests
    desc "when init"
    subject{ url_class.new(router1, url_path1, url_name1) }

    setup do
      Assert.stub_on_call(
        MuchRails::RailsRoutes.instance,
        :method_missing,
      ) do |call|
        @rails_routes_method_missing_call = call
        "TEST PATH OR URL STRING"
      end
    end

    let(:url_name1){ Factory.symbol }
    let(:url_path1){ Factory.url }
    let(:router1){ unit_class.new }

    should have_imeths :path_for, :url_for

    should "know its attributes" do
      path_string = subject.path_for(test: "args", format: "html")
      assert_that(path_string).equals("TEST PATH OR URL STRING")
      assert_that(@rails_routes_method_missing_call.args)
        .equals(["#{url_name1}_path".to_sym, { test: "args" }])

      url_string = subject.url_for(test: "args", format: "xml")
      assert_that(url_string).equals("TEST PATH OR URL STRING")
      assert_that(@rails_routes_method_missing_call.args)
        .equals(["#{url_name1}_url".to_sym, { test: "args" }])
    end
  end

  class FakeApplicationRoutes
    attr_reader :get_calls, :post_calls, :put_calls, :patch_calls, :delete_calls

    def initialize
      @get_calls    = []
      @post_calls   = []
      @put_calls    = []
      @patch_calls  = []
      @delete_calls = []
    end

    def get(*args)
      @get_calls << Assert::StubCall.new(*args)
    end

    def post(*args)
      @post_calls << Assert::StubCall.new(*args)
    end

    def put(*args)
      @put_calls << Assert::StubCall.new(*args)
    end

    def patch(*args)
      @patch_calls << Assert::StubCall.new(*args)
    end

    def delete(*args)
      @delete_calls << Assert::StubCall.new(*args)
    end
  end
end
