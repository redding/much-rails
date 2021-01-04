# frozen_string_literal: true

require "assert"
require "much-rails/action/redirect_to_result"

class MuchRails::Action::RedirectToResult
  class UnitTests < Assert::Context
    desc "MuchRails::Action::RedirectToResult"
    subject { unit_class }

    let(:unit_class) { MuchRails::Action::RedirectToResult }
  end

  class InitTests < UnitTests
    desc "when init"
    subject { unit_class.new("URL") }

    should "know its attributes" do
      assert_that(subject.command_name).equals(:redirect_to)
      assert_that(subject.command_args).equals(["URL"])
      assert_that(subject.redirect_to_args).equals(subject.command_args)
    end
  end
end
