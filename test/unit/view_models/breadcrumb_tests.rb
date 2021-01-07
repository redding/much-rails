# frozen_string_literal: true

require "assert"
require "much-rails/view_models/breadcrumb"

class MuchRails::ViewModels::Breadcrumb
  class UnitTests < Assert::Context
    desc "MuchRails::ViewModels::Breadcrumb"
    subject{ unit_class }

    let(:unit_class){ MuchRails::ViewModels::Breadcrumb }
  end

  class InitTests < UnitTests
    desc "when init"
    subject{ unit_class.new }

    let(:name){ "name" }
    let(:url){ "url" }

    should have_readers :name, :url

    should have_imeths :render_as_link?

    should "know its name" do
      assert_that(subject.name).is_nil

      result = unit_class.new(name)
      assert_that(result.name).equals(name)

      result = unit_class.new(name, url)
      assert_that(result.name).equals(name)
    end

    should "know its url" do
      assert_that(subject.url).is_nil

      result = unit_class.new(name)
      assert_that(result.url).is_nil

      result = unit_class.new(name, url)
      assert_that(result.url).equals(url)
    end

    should "know if it should render as link" do
      result = unit_class.new(name, url)
      assert_that(result.render_as_link?).is_true

      result = unit_class.new(name)
      assert_that(result.render_as_link?).is_false
    end
  end
end
