require "assert"
require "much-rails/call_method"

module MuchRails::CallMethodTest
  class UnitTests < Assert::Context
    desc "MuchRails::CallMethod"
    subject { unit_class }

    let(:unit_class) { MuchRails::CallMethod }

    should "include MuchRails::Plugin" do
      assert_that(subject).includes(MuchRails::Plugin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject { receiver_class }

    setup do
      Assert.stub_tap(subject, :new) { |new_object|
        @new_class_method_called = true

        Assert.stub(new_object, :on_call) {
          @on_call_instance_method_called = true
        }
      }
    end

    let(:receiver_class) {
      Class.new do
        include MuchRails::CallMethod
      end
    }

    should have_imeths :call

    should "call #new and #call" do
      subject.call

      assert_that(@new_class_method_called).is_true
      assert_that(@on_call_instance_method_called).is_true
    end
  end

  class ReceiverWithOnCallNotImplemented < UnitTests
    desc "with the #on_call method not implemented"
    subject { receiver_class }

    let(:receiver_class) {
      Class.new do
        include MuchRails::CallMethod
      end
    }

    should "not implement its #call method" do
      assert_that(-> { subject.call }).raises(NotImplementedError)
    end
  end
end
