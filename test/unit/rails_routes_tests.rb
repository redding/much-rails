# frozen_string_literal: true

require "assert"
require "much-rails/rails_routes"

class MuchRails::RailsRoutes
  class UnitTests < Assert::Context
    desc "MuchRails::RailsRoutes"
    subject { unit_class }

    let(:unit_class) { MuchRails::RailsRoutes }

    should "include Singleton, Rails url helpers" do
      assert_that(subject).includes(Singleton)
      assert_that(subject).includes(::Rails.application.routes.url_helpers)
    end
  end

  class InitTests < UnitTests
    desc "when init"
    subject { unit_class.instance }

    should "know its default URL options" do
      assert_that(subject.__send__(:default_url_options))
        .equals(::Rails.application.config.action_mailer.default_url_options)
    end
  end
end
