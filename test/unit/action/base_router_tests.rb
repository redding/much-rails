require "assert"
require "much-rails/action/base_router"

class MuchRails::Action::BaseRouter
  class UnitTests < Assert::Context
    desc "MuchRails::Action::BaseRouter"
    subject { unit_class }

    let(:unit_class) { MuchRails::Action::BaseRouter }

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
      Assert.stub_tap_on_call(unit_class::URLSet, :new) { |url_set, call|
        @url_set_new_call = call
        Assert.stub_on_call(url_set, :path_for) { |call|
          @url_set_path_for_call = call
        }
        Assert.stub_on_call(url_set, :url_for) { |call|
          @url_set_url_for_call = call
        }
        Assert.stub_tap_on_call(url_set, :add) { |_, call|
          @url_set_add_call = call
        }
      }
    end

    should have_readers :name
    should have_readers :url_set, :request_types, :routes, :definitions

    should have_imeths :url_class, :apply_to
    should have_imeths :path_for, :url_for
    should have_imeths :base_url, :url

    should "know its default attributes" do
      assert_that(subject.name).is_nil
      assert_that(subject.url_set).is_empty
      assert_that(subject.request_types).equals([])
      assert_that(subject.routes).equals([])
      assert_that(subject.definitions).equals([])
      assert_that(subject.base_url).equals(unit_class::DEFAULT_BASE_URL)
      assert_that(subject.url_class).equals(unit_class.url_class)

      assert_that(@url_set_new_call.args).equals([subject])
    end

    should "not implement #apply_to" do
      assert_that{ subject.apply_to("TEST SCOPE") }.raises(NotImplementedError)
    end

    should "allow customing the base URL" do
      subject.base_url(new_url = Factory.url)
      assert_that(subject.base_url).equals(new_url)
    end

    should "allow defining URLs" do
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

    should have_imeths :empty?, :add, :get, :path_for, :url_for

    should "add URLs" do
      assert_that(subject).is_empty

      url = subject.add(:url1.to_s, path = Factory.url)
      assert_that(subject).is_not_empty
      assert_that(url).is_kind_of(router1.url_class)
      assert_that(@url_new_call.args).equals([:url1, path, router1])

      ex =
        assert_that{ subject.add(:url1, Factory.url) }.raises(ArgumentError)
      assert_that(ex.message).equals("There is already a URL named `:url1`.")
    end

    should "get URLs" do
      ex =
        assert_that{ subject.get(:url1) }.raises(ArgumentError)
      assert_that(ex.message).equals("There is no URL named `:url1`.")

      added_url = subject.add(:url1, Factory.url)
      url       = subject.get(:url1)
      assert_that(url).is(added_url)

      url = subject.get(:url1.to_s)
      assert_that(url).is(added_url)
    end

    should "build path/URL string for named URLs" do
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

    let(:url_name1) { Factory.symbol }
    let(:url_path1) { Factory.url }
    let(:router1) { unit_class.new }

    should have_imeths :url_name, :url_path

    should "know its URL name" do
      assert_that(subject.url_name(nil, nil)).is_nil
      assert_that(subject.url_name(nil, router1)).is_nil
      assert_that(subject.url_name(url_name1, nil)).equals(url_name1)
      assert_that(subject.url_name(url_name1, router1)).equals(url_name1)

      router_name = Factory.symbol
      Assert.stub(router1, :name) { router_name }
      assert_that(subject.url_name(url_name1, router1))
        .equals("#{router_name}_#{url_name1}".to_sym)
    end

    should "know its URL path" do
      assert_that(subject.url_path(nil, nil)).is_nil
      assert_that(subject.url_path(nil, router1)).is_nil
      assert_that(subject.url_path(url_path1, nil)).equals(url_path1)
      assert_that(subject.url_path(url_path1, router1)).equals(url_path1)

      router_base_url = Factory.url
      Assert.stub(router1, :base_url) { router_base_url }
      assert_that(subject.url_path(url_path1, router1))
        .equals(File.join(router_base_url, url_path1))
    end
  end

  class BaseURLInitTests < BaseURLUnitTests
    desc "when init"
    subject { base_url_class.new(url_name1, url_path1, router1) }

    should have_imeths :name, :path, :path_for, :url_for

    should "know its attributes" do
      assert_that(subject.name)
        .equals(base_url_class.url_name(url_name1, router1))
      assert_that(subject.path)
        .equals(base_url_class.url_path(url_path1, router1))

      assert_that{ subject.path_for("TEST ARGS") }.raises(NotImplementedError)
      assert_that{ subject.url_for("TEST ARGS") }.raises(NotImplementedError)
    end
  end
end
