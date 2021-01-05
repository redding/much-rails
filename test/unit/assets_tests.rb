# frozen_string_literal: true

require "assert"
require "much-rails/assets"

module MuchRails::Assets
  class UnitTests < Assert::Context
    desc "MuchRails::Assets"
    subject{ unit_class }

    let(:unit_class){ MuchRails::Assets }

    should have_imeths :configure_for_rails

    should "be Dassets" do
      assert_that(unit_class).is(Dassets)
    end
  end

  class ConfigureTests < UnitTests
    desc "when configured"

    setup do
      subject.reset

      in_development_env = Factory.boolean
      Assert.stub(FakeRails.env, :development?){ in_development_env }
      Assert.stub(FakeRails.env, :test?){ !in_development_env }

      Assert.stub_on_call(subject, :init) do |call|
        @init_call = call
      end

      subject.configure_for_rails(FakeRails)
    end

    should "configure the fingerprint cache to use a memory cache" do
      assert_that(subject.config.fingerprint_cache)
        .is_instance_of(subject::MemCache)
    end

    should "configure the content cache to use a memory cache" do
      assert_that(subject.config.content_cache)
        .is_instance_of(subject::MemCache)
    end

    should "not configure a file store" do
      assert_that(subject.config.file_store.root)
        .is_not_equal_to(FakeRails.root.join("public"))
    end

    should "configure the app's app/assets folder as a source" do
      source =
        subject.config.sources.detect do |source|
          source.path == FakeRails.root.join("app", "assets").to_s
        end

      assert_that(source).is_not_nil
      assert_that(source.engines["js"].size).equals(1)
      assert_that(source.engines["js"].first)
        .is_instance_of(subject::Erubi::Engine)
      assert_that(source.engines["scss"].size).equals(2)
      assert_that(source.engines["scss"].first)
        .is_instance_of(subject::Erubi::Engine)
      assert_that(source.engines["scss"].last)
        .is_instance_of(subject::Sass::Engine)
    end

    should "initialize itself" do
      assert_that(@init_call).is_not_nil
    end
  end

  class ConfigureNotInDevelopmentOrTestEnvsTests < UnitTests
    desc "when configured not in development or test environments"

    setup do
      subject.reset

      Assert.stub_on_call(subject, :init) do |call|
        @init_call = call
      end

      subject.configure_for_rails(FakeRails)
    end

    should "configure the content cache to use no cache" do
      assert_that(subject.config.content_cache)
        .is_instance_of(subject::NoCache)
    end

    should "configure a file store for the app's public folder" do
      assert_that(subject.config.file_store.root)
        .equals(FakeRails.root.join("public"))
    end
  end

  module FakeRails
    def self.env
      @env ||= FakeRailsEnv.new
    end

    def self.root
      @root ||= FakeRailsRoot.new
    end
  end

  class FakeRailsEnv
    def development?
      false
    end

    def test?
      false
    end
  end

  class FakeRailsRoot
    def initialize
      @root_path = Pathname.new(Factory.path)
    end

    def join(*args)
      @root_path.join(File.join(*args))
    end
  end
end
