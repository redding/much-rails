# frozen_string_literal: true

require "assert"
require "much-rails/layout"

module MuchRails::Layout
  class UnitTests < Assert::Context
    desc "MuchRails::Layout"
    subject{ unit_module }

    let(:unit_module){ MuchRails::Layout }

    should "include MuchRails::Mixin" do
      assert_that(subject).includes(MuchRails::Mixin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject{ receiver_class }

    let(:receiver_class) do
      Class.new do
        include MuchRails::Layout

        def attribute1
          "attribute1"
        end
      end
    end

    should have_imeths :page_title, :page_titles, :application_page_title
    should have_imeths :breadcrumb, :breadcrumbs
    should have_imeths :stylesheet, :stylesheets, :javascript, :javascripts
    should have_imeths :external_javascript, :external_javascripts
    should have_imeths :head_link, :head_links, :layout, :layouts
  end

  class InitTests < ReceiverTests
    desc "when init"
    subject{ receiver_class.new }

    should "know its page title" do
      assert_that(subject.page_title).is_nil

      receiver_class.page_title{ "Some Portal" }
      receiver_class.page_title{ "Some Resource #{attribute1}" }

      assert_that(subject.page_title).equals("Some Resource attribute1")
    end

    should "know its application page title" do
      assert_that(subject.application_page_title).is_nil

      receiver_class.application_page_title{ "Some App" }
      receiver_class.application_page_title{ "Some App #{attribute1}" }

      assert_that(subject.application_page_title).equals("Some App attribute1")
    end

    should "know its full page title "\
           "given no application page title or page title segments" do
      assert_that(subject.full_page_title).is_nil
    end

    should "know its full page title "\
           "given an application page title but no page title segments" do
      receiver_class.application_page_title{ "Some App" }

      assert_that(subject.full_page_title)
        .equals(subject.application_page_title)
    end

    should "know its full page title "\
           "given no application page title but page title segments" do
      receiver_class.page_title{ "Some Portal" }
      receiver_class.page_title{ "Some Resource #{attribute1}" }

      assert_that(subject.full_page_title)
        .equals("Some Resource attribute1 - Some Portal")
    end

    should "know its full page title "\
           "given both an application page title and page title segments" do
      receiver_class.application_page_title{ "Some App" }
      receiver_class.page_title{ "Some Portal" }
      receiver_class.page_title{ "Some Resource #{attribute1}" }

      assert_that(subject.full_page_title)
        .equals("Some Resource attribute1 - Some Portal | Some App")
    end

    should "know its breadcrumbs" do
      receiver = receiver_class.new
      assert_that(receiver.any_breadcrumbs?).is_false
      assert_that(receiver.breadcrumbs).is_empty

      receiver_class.breadcrumb{ ["Item1", "item1-url"] }
      receiver_class.breadcrumb{ "Item2" }
      assert_that(subject.any_breadcrumbs?).is_true
      assert_that(subject.breadcrumbs)
        .equals([
          MuchRails::ViewModels::Breadcrumb.new("Item1", "item1-url"),
          MuchRails::ViewModels::Breadcrumb.new("Item2"),
        ])
    end

    should "know its stylesheets" do
      receiver = receiver_class.new
      assert_that(receiver.stylesheets).is_empty

      receiver_class.stylesheet("some/stylesheet.css")
      receiver_class.stylesheet{ "some/other-stylesheet.css" }

      assert_that(subject.stylesheets)
        .equals([
          "some/stylesheet.css",
          "some/other-stylesheet.css",
        ])
    end

    should "know its javascripts" do
      receiver = receiver_class.new
      assert_that(receiver.javascripts).is_empty

      receiver_class.javascript("some/javascript/pack.js")
      receiver_class.javascript{ "some/other/javascript/pack.js" }
      receiver_class.javascript("https://some/javascript/file.js")
      receiver_class.javascript{ "https://some/other/javascript/file.js" }

      assert_that(subject.javascripts)
        .equals([
          "some/javascript/pack.js",
          "some/other/javascript/pack.js",
          "https://some/javascript/file.js",
          "https://some/other/javascript/file.js",
        ])
    end

    should "know its external_javascripts" do
      receiver = receiver_class.new
      assert_that(receiver.external_javascripts).is_empty

      receiver_class.external_javascript("some/ext_js/pack.js")
      receiver_class.external_javascript{ "some/other/ext_js/pack.js" }
      receiver_class.external_javascript("https://some/ext_js/file.js")
      receiver_class.external_javascript{ "https://some/other/ext_js/file.js" }

      assert_that(subject.external_javascripts)
        .equals([
          "some/ext_js/pack.js",
          "some/other/ext_js/pack.js",
          "https://some/ext_js/file.js",
          "https://some/other/ext_js/file.js",
        ])
    end

    should "know its head links" do
      receiver = receiver_class.new
      assert_that(receiver.head_links).is_empty

      url1 = Factory.url
      attributes1 = { some_attribute: Factory.string }
      receiver_class.head_link(url1, **attributes1)

      assert_that(subject.head_links)
        .equals([unit_module::HeadLink.new(url1, **attributes1)])
    end

    should "know its #layouts" do
      assert_that(subject.layouts).equals(receiver_class.layouts)
    end
  end
end
