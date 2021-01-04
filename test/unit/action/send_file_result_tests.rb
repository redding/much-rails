# frozen_string_literal: true

require "assert"
require "much-rails/action/send_file_result"

class MuchRails::Action::SendFileResult
  class UnitTests < Assert::Context
    desc "MuchRails::Action::SendFileResult"
    subject { unit_class }

    let(:unit_class) { MuchRails::Action::SendFileResult }
  end

  class InitTests < UnitTests
    desc "when init"
    subject { unit_class.new("FILE") }

    should "know its attributes" do
      assert_that(subject.command_name).equals(:send_file)
      assert_that(subject.command_args).equals(["FILE"])
      assert_that(subject.send_file_args).equals(subject.command_args)
    end
  end
end
