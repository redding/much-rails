# frozen_string_literal: true

require "assert"
require "much-rails/action/base_result"

class MuchRails::Action::BaseResult
  class UnitTests < Assert::Context
    desc "MuchRails::Action::BaseResult"
    subject { unit_class }

    let(:unit_class) { MuchRails::Action::BaseResult }
  end

  class InitTests < UnitTests
    desc "when init"
    subject { unit_class.new }

    should "not implement its #execute_block method" do
      assert_that { subject.execute_block }.raises(NotImplementedError)
    end
  end
end
