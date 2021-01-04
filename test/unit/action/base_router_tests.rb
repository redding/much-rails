# frozen_string_literal: true

require "assert"
require "much-rails/action/base_router"

class MuchRails::Action::BaseRouter
  class UnitTests < Assert::Context
    desc "MuchRails::Action::BaseRouter"
    subject { unit_class }

    let(:unit_class) { MuchRails::Action::BaseRouter }

    let(:caller1) { ["TEST CALLER 1"] }

    should have_imeths :url_class

    should "know its constants" do
      assert_that(subject::DEFAULT_BASE_URL).equals("/")
      assert_that(subject.url_class).equals(unit_class::BaseURL)
    end
  end

  class InitTests < UnitTests
    desc "when init"
    subject { unit_class.new }

    setup do
      Assert.stub_tap_on_call(unit_class::RequestTypeSet, :new) { |set, _|
        Assert.stub_tap_on_call(set, :add) { |_, call|
          @request_type_set_add_call = call
        }
      }
      Assert.stub_tap_on_call(unit_class::URLSet, :new) { |set, call|
        @url_set_new_call = call
        Assert.stub_on_call(set, :path_for) { |call|
          @url_set_path_for_call = call
          "TEST PATH STRING"
        }
        Assert.stub_on_call(set, :url_for) { |call|
          @url_set_url_for_call = call
          "TEST URL STRING"
        }
        Assert.stub_tap_on_call(set, :add) { |_, call|
          @url_set_add_call = call
        }
      }
      Assert.stub_tap_on_call(unit_class::Definition, :for_route) { |_, call|
        @route_definition_call = call
      }
    end

    should have_readers :name
    should have_readers :request_type_set, :url_set, :definitions

    should have_imeths :url_class, :apply_to
    should have_imeths :path_for, :url_for
    should have_imeths :request_type
    should have_imeths :base_url, :url
    should have_imeths :get, :post, :put, :patch, :delete

    should "know its default attributes" do
      assert_that(subject.name).is_nil
      assert_that(subject.request_type_set).is_empty
      assert_that(subject.url_set).is_empty
      assert_that(subject.definitions).is_empty
      assert_that(subject.base_url).equals(unit_class::DEFAULT_BASE_URL)
      assert_that(subject.url_class).equals(unit_class.url_class)

      assert_that(@url_set_new_call.args).equals([subject])
    end

    should "instance_exec any given block" do
      router = unit_class.new { base_url "/test" }
      assert_that(router.base_url).equals("/test")
    end

    should "not implement #apply_to" do
      assert_that{ subject.apply_to("TEST SCOPE") }.raises(NotImplementedError)
    end

    should "build path/URL strings for named URLs" do
      path_string = subject.path_for(:url1, "TEST PATH ARGS")
      assert_that(path_string).equals("TEST PATH STRING")
      assert_that(@url_set_path_for_call.args).equals([:url1, "TEST PATH ARGS"])

      url_string = subject.url_for(:url1, "TEST URL ARGS")
      assert_that(url_string).equals("TEST URL STRING")
      assert_that(@url_set_url_for_call.args).equals([:url1, "TEST URL ARGS"])
    end

    should "define request types" do
      proc = ->(request) {}
      request_type = subject.request_type(:type1, &proc)
      assert_that(subject.request_type_set).is_not_empty
      assert_that(request_type).is_instance_of(unit_class::RequestType)
      assert_that(@request_type_set_add_call.args).equals([:type1, proc])
    end

    should "define the base URL" do
      subject.base_url(new_url = Factory.url)
      assert_that(subject.base_url).equals(new_url)
    end

    should "define URLs" do
      url = subject.url(:url1, path = Factory.url)
      assert_that(subject.url_set).is_not_empty
      assert_that(url).is_kind_of(subject.url_class)
      assert_that(@url_set_add_call.args).equals([:url1, path])

      ex =
        assert_that{ subject.url(:url2.to_s, Factory.url) }
          .raises(ArgumentError)
      assert_that(ex.message)
        .equals(
          "Named URLs must be defined with Symbol names, given `\"url2\"`."
        )

      ex =
        assert_that{ subject.url(:url2, path = Factory.url.to_sym) }
          .raises(ArgumentError)
      assert_that(ex.message)
        .equals(
          "Named URLs must be defined with String paths, given `#{path.inspect}`."
        )
    end

    should "define HTTP method routes" do
      request_type_name = Factory.symbol
      request_type_proc = ->(request) {}
      request_type = subject.request_type(request_type_name, &request_type_proc)
      request_type_class_name = Factory.string
      request_type_action =
        unit_class::RequestTypeAction.new(request_type, request_type_class_name)
      url_name = Factory.symbol
      url_path = Factory.url
      url = subject.url(url_name, url_path)
      default_class_name = Factory.string

      definition =
        subject.get(
          url_name,
          default_class_name,
          called_from: caller1,
          **{ request_type_name => request_type_class_name },
        )
      assert_that(subject.definitions.size).equals(1)
      assert_that(definition).is_instance_of(unit_class::Definition)
      assert_that(@route_definition_call.kargs)
        .equals(
          http_method: :get,
          url: url,
          default_action_class_name: default_class_name,
          request_type_actions: [request_type_action],
          called_from: caller1,
        )

      definition =
        subject.post(url_name, default_class_name, called_from: caller1)
      assert_that(subject.definitions.size).equals(2)
      assert_that(definition).is_instance_of(unit_class::Definition)
      assert_that(@route_definition_call.kargs)
        .equals(
          http_method: :post,
          url: url,
          default_action_class_name: default_class_name,
          request_type_actions: [],
          called_from: caller1,
        )

      definition =
        subject.put(url_path, default_class_name, called_from: caller1)
      assert_that(subject.definitions.size).equals(3)
      assert_that(definition).is_instance_of(unit_class::Definition)
      assert_that(@route_definition_call.kargs)
        .equals(
          http_method: :put,
          url: subject.url_class.for(subject, url_path),
          default_action_class_name: default_class_name,
          request_type_actions: [],
          called_from: caller1,
        )

      definition =
        subject.patch(url_name, default_class_name, called_from: caller1)
      assert_that(subject.definitions.size).equals(4)
      assert_that(definition).is_instance_of(unit_class::Definition)
      assert_that(@route_definition_call.kargs)
        .equals(
          http_method: :patch,
          url: url,
          default_action_class_name: default_class_name,
          request_type_actions: [],
          called_from: caller1,
        )

      definition =
        subject.delete(url_name, default_class_name, called_from: caller1)
      assert_that(subject.definitions.size).equals(5)
      assert_that(definition).is_instance_of(unit_class::Definition)
      assert_that(@route_definition_call.kargs)
        .equals(
          http_method: :delete,
          url: url,
          default_action_class_name: default_class_name,
          request_type_actions: [],
          called_from: caller1,
        )
    end
  end

  class RequestTypeSetUnitTests < UnitTests
    desc "RequestTypeSet"
    subject { request_type_set_class }

    let(:request_type_set_class) { unit_class::RequestTypeSet }
    let(:request_type_class) { unit_class::RequestType }
  end

  class RequestTypeSetInitTests < RequestTypeSetUnitTests
    desc "when init"
    subject { request_type_set_class.new }

    setup do
      Assert.stub_tap_on_call(request_type_class, :new) { |url, call|
        @request_type_new_call = call
      }
    end

    let(:constraints_lambda1) { ->(request) {} }

    should have_imeths :empty?, :add, :get

    should "add request types" do
      assert_that(subject).is_empty

      request_type = subject.add(:type1.to_s, constraints_lambda1)
      assert_that(subject).is_not_empty
      assert_that(request_type).is_instance_of(request_type_class)
      assert_that(@request_type_new_call.args)
        .equals([:type1, constraints_lambda1])

      ex =
        assert_that{ subject.add(:type1, constraints_lambda1) }
          .raises(ArgumentError)
      assert_that(ex.message)
        .equals("There is already a request type named `:type1`.")
    end

    should "get request types" do
      ex =
        assert_that{ subject.get(:type1) }.raises(ArgumentError)
      assert_that(ex.message).equals("There is no request type named `:type1`.")

      added_request_type = subject.add(:type1.to_s, constraints_lambda1)
      request_type       = subject.get(:type1)
      assert_that(request_type).is(added_request_type)

      request_type = subject.get(:type1)
      assert_that(request_type).is(added_request_type)
    end
  end

  class RequestTypeUnitTests < UnitTests
    desc "RequestType"
    subject { request_type_class }

    let(:request_type_class) { unit_class::RequestType }
  end

  class RequestTypeInitTests < RequestTypeUnitTests
    desc "when init"
    subject { request_type_class.new(name1, constraints_lambda1) }

    let(:name1) { Factory.symbol }
    let(:constraints_lambda1) { ->(request) {} }

    should have_imeths :name, :constraints_lambda

    should "know its attributes" do
      assert_that(subject.name).equals(name1)
      assert_that(subject.constraints_lambda).equals(constraints_lambda1)
    end
  end

  class RequestTypeActionUnitTests < UnitTests
    desc "RequestTypeAction"
    subject { request_type_action_class }

    let(:request_type_action_class) { unit_class::RequestTypeAction }
  end

  class RequestTypeActionInitTests < RequestTypeActionUnitTests
    desc "when init"
    subject { request_type_action_class.new(request_type1, action_class_name1) }

    let(:name1) { Factory.symbol }
    let(:constraints_lambda1) { ->(request) {} }
    let(:request_type1) {
      unit_class::RequestType.new(name1, constraints_lambda1)
    }
    let(:action_class_name1) { Factory.string }

    should have_imeths :request_type, :class_name, :constraints_lambda

    should "know its attributes" do
      assert_that(subject.request_type).equals(request_type1)
      assert_that(subject.class_name).equals(action_class_name1)
      assert_that(subject.constraints_lambda)
        .equals(request_type1.constraints_lambda)
    end
  end

  class URLSetUnitTests < UnitTests
    desc "URLSet"
    subject { url_set_class }

    let(:url_set_class) { unit_class::URLSet }
  end

  class URLSetInitTests < URLSetUnitTests
    desc "when init"
    subject { url_set_class.new(router1) }

    setup do
      Assert.stub_tap_on_call(router1.url_class, :new) { |url, call|
        @url_new_call = call
        Assert.stub_on_call(url, :path_for) { |call|
          @url_path_for_call = call
          "TEST PATH STRING"
        }
        Assert.stub_on_call(url, :url_for) { |call|
          @url_url_for_call = call
          "TEST URL STRING"
        }
      }
    end

    let(:router1) { unit_class.new }

    should have_imeths :empty?, :add, :fetch, :path_for, :url_for

    should "add URLs" do
      assert_that(subject).is_empty

      url = subject.add(:url1.to_s, path = Factory.url)
      assert_that(subject).is_not_empty
      assert_that(url).is_kind_of(router1.url_class)
      assert_that(@url_new_call.args).equals([router1, path, :url1])

      ex =
        assert_that{ subject.add(:url1, Factory.url) }.raises(ArgumentError)
      assert_that(ex.message).equals("There is already a URL named `:url1`.")
    end

    should "fetch URLs" do
      ex =
        assert_that{ subject.fetch(:url1) }.raises(ArgumentError)
      assert_that(ex.message).equals("There is no URL named `:url1`.")
      assert_that(subject.fetch(:url1) { "/url1" }).equals("/url1")

      added_url = subject.add(:url1, Factory.url)
      url       = subject.fetch(:url1)
      assert_that(url).is(added_url)

      url = subject.fetch(:url1.to_s)
      assert_that(url).is(added_url)
    end

    should "build path/URL strings for named URLs" do
      ex =
        assert_that{ subject.path_for(:url1) }.raises(ArgumentError)
      assert_that(ex.message).equals("There is no URL named `:url1`.")
      ex =
        assert_that{ subject.url_for(:url1) }.raises(ArgumentError)
      assert_that(ex.message).equals("There is no URL named `:url1`.")

      subject.add(:url1, Factory.url)

      path_string = subject.path_for(:url1, "TEST PATH ARGS")
      assert_that(path_string).equals("TEST PATH STRING")
      assert_that(@url_path_for_call.args).equals(["TEST PATH ARGS"])

      url_string = subject.url_for(:url1, "TEST URL ARGS")
      assert_that(url_string).equals("TEST URL STRING")
      assert_that(@url_url_for_call.args).equals(["TEST URL ARGS"])
    end
  end

  class BaseURLUnitTests < UnitTests
    desc "BaseURL"
    subject { base_url_class }

    let(:base_url_class) { unit_class::BaseURL }

    let(:router1) { unit_class.new }
    let(:url_path1) { Factory.url }
    let(:url_name1) { Factory.symbol }

    should have_imeths :url_name, :url_path, :for

    should "know its URL name" do
      assert_that(subject.url_name(nil, nil)).is_nil
      assert_that(subject.url_name(router1, nil)).is_nil
      assert_that(subject.url_name(nil, url_name1)).equals(url_name1)
      assert_that(subject.url_name(router1, url_name1)).equals(url_name1)

      router_name = Factory.symbol
      Assert.stub(router1, :name) { router_name }
      assert_that(subject.url_name(router1, url_name1))
        .equals("#{router_name}_#{url_name1}".to_sym)
    end

    should "know its URL path" do
      assert_that(subject.url_path(nil, nil)).is_nil
      assert_that(subject.url_path(router1, nil)).is_nil
      assert_that(subject.url_path(nil, url_path1)).equals(url_path1)
      assert_that(subject.url_path(router1, url_path1)).equals(url_path1)

      router_base_url = Factory.url
      Assert.stub(router1, :base_url) { router_base_url }
      assert_that(subject.url_path(router1, url_path1))
        .equals(File.join(router_base_url, url_path1))
    end

    should "build URLs from an existing URL or a path string" do
      url1 = base_url_class.new(router1, url_path1, url_name1)

      url = base_url_class.for(router1, url1)
      assert_that(url).is(url1)

      url = base_url_class.for(router1, url_path1)
      assert_that(url.path).equals(url1.path)
    end
  end

  class BaseURLInitTests < BaseURLUnitTests
    desc "when init"
    subject { base_url_class.new(router1, url_path1, url_name1) }

    should have_readers :router, :url_path, :url_name
    should have_imeths :name, :path, :path_for, :url_for

    should "know its attributes" do
      assert_that(subject.name)
        .equals(base_url_class.url_name(router1, url_name1))
      assert_that(subject.path)
        .equals(base_url_class.url_path(router1, url_path1))

      assert_that{ subject.path_for("TEST ARGS") }.raises(NotImplementedError)
      assert_that{ subject.url_for("TEST ARGS") }.raises(NotImplementedError)
    end
  end

  class DefinitionUnitTests < UnitTests
    desc "Definition"
    subject { definition_class }

    let(:definition_class) { unit_class::Definition }

    let(:router1) { unit_class.new }
    let(:http_method1) { Factory.symbol }
    let(:url1) { unit_class::BaseURL.for(router1, Factory.url) }
    let(:url_path1) { url1.path }
    let(:url_name1) { url1.name }
    let(:default_action_class_name1) { Factory.string }
    let(:request_type_actions1) { [] }

    should have_imeths :for_route

    should "build definitions given route information" do
      definition1 =
        definition_class.new(
          http_method: http_method1,
          path: url_path1,
          name: url_name1,
          default_action_class_name: default_action_class_name1,
          request_type_actions: request_type_actions1,
          called_from: caller1,
        )

      definition =
        definition_class.for_route(
          http_method: http_method1,
          url: url1,
          default_action_class_name: default_action_class_name1,
          request_type_actions: request_type_actions1,
          called_from: caller1,
        )
      assert_that(definition).equals(definition1)
    end
  end

  class DefinitionInitTests < DefinitionUnitTests
    desc "when init"
    subject {
      definition_class.new(
        http_method: http_method1,
        path: url_path1,
        name: url_name1,
        default_action_class_name: default_action_class_name1,
        request_type_actions: request_type_actions1,
        default_params: default_params1,
        called_from: caller1,
      )
    }

    let(:default_params1) {
      { Factory.string => Factory.string }
    }

    should have_readers :http_method, :path, :name, :default_params
    should have_readers :default_action_class_name, :request_type_actions
    should have_reader :called_from

    should "know its attributes" do
      assert_that(subject.http_method).equals(http_method1)
      assert_that(subject.path).equals(url_path1)
      assert_that(subject.name).equals(url_name1)
      assert_that(subject.default_params).equals(default_params1)
      assert_that(subject.default_action_class_name)
        .equals(default_action_class_name1)
      assert_that(subject.request_type_actions).equals(request_type_actions1)
      assert_that(subject.called_from).equals(caller1)
    end
  end
end
