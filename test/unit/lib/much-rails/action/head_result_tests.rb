require "assert"
require "much-rails/action/head_result"

class MuchRails::Action::HeadResult
  class UnitTests < Assert::Context
    desc "MuchRails::Action::HeadResult"
    subject { unit_class }

    let(:unit_class) { MuchRails::Action::HeadResult }
  end

  class InitTests < UnitTests
    desc "when init"
    subject { unit_class.new(:ok) }

    should "know its attributes" do
      assert_that(subject.command_name).equals(:head)
      assert_that(subject.command_args).equals([:ok])
      assert_that(subject.head_args).equals(subject.command_args)
    end
  end
end
