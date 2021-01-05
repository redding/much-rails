# frozen_string_literal: true

require "assert"
require "much-rails/service"

module MuchRails::Service
  class UnitTests < Assert::Context
    desc "MuchRails::Service"
    subject{ unit_class }

    let(:unit_class){ MuchRails::Service }

    should "include MuchRails::Mixin" do
      assert_that(subject).includes(MuchRails::Mixin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject{ receiver_class }

    let(:receiver_class) do
      Class.new do
        include MuchRails::Service
      end
    end

    should "be configured as expected" do
      assert_that(subject).includes(MuchRails::CallMethodCallbacks)
      assert_that(subject).includes(MuchRails::WrapAndCallMethod)
    end
  end
end
