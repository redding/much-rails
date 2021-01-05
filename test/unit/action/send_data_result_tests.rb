# frozen_string_literal: true

require "assert"
require "much-rails/action/send_data_result"

class MuchRails::Action::SendDataResult
  class UnitTests < Assert::Context
    desc "MuchRails::Action::SendDataResult"
    subject{ unit_class }

    let(:unit_class){ MuchRails::Action::SendDataResult }
  end

  class InitTests < UnitTests
    desc "when init"
    subject{ unit_class.new("DATA") }

    should "know its attributes" do
      assert_that(subject.command_name).equals(:send_data)
      assert_that(subject.command_args).equals(["DATA"])
      assert_that(subject.send_data_args).equals(subject.command_args)
    end
  end
end
