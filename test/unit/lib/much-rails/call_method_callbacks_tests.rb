require "assert"
require "much-rails/call_method_callbacks"

require "much-plugin"
require "much-rails/call_method"
require "much-rails/config"

module MuchRails::CallMethodCallbacks
  class UnitTests < Assert::Context
    desc "MuchRails::SaveService"
    subject { unit_class }

    let(:unit_class) { MuchRails::CallMethodCallbacks }

    should "include MuchPlugin" do
      assert_that(subject).includes(MuchPlugin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject { receiver_class }

    let(:receiver_class) {
      Class.new do
        include MuchRails::CallMethodCallbacks

        attr_reader :values

        def initialize
          @values = []
        end
      end
    }

    let(:proc1) { -> {} }
    let(:proc2) { -> {} }

    should have_imeths :before_call, :prepend_before_call, :after_call
    should have_imeths :prepend_after_call, :around_call, :prepend_around_call
    should have_imeths :call

    should "be configured as expected" do
      assert_that(subject).includes(MuchRails::CallMethod)
      assert_that(subject).includes(MuchRails::Config)
    end

    should "know its attributes" do
      # before_callbacks
      assert_that(
        subject.much_rails_call_callbacks_config.before_callbacks.size
      ).equals(0)

      subject.before_call(&proc1)
      assert_that(
        subject.much_rails_call_callbacks_config.before_callbacks.size
      ).equals(1)
      assert_that(subject.much_rails_call_callbacks_config.before_callbacks)
        .equals([proc1])

      subject.prepend_before_call(&proc2)
      assert_that(
        subject.much_rails_call_callbacks_config.before_callbacks.size
      ).equals(2)
      assert_that(subject.much_rails_call_callbacks_config.before_callbacks)
        .equals([proc2, proc1])

      # after_callbacks
      assert_that(subject.much_rails_call_callbacks_config.after_callbacks.size)
        .equals(0)

      subject.after_call(&proc1)
      assert_that(subject.much_rails_call_callbacks_config.after_callbacks.size)
        .equals(1)
      assert_that(subject.much_rails_call_callbacks_config.after_callbacks)
        .equals([proc1])

      subject.prepend_after_call(&proc2)
      assert_that(subject.much_rails_call_callbacks_config.after_callbacks.size)
        .equals(2)
      assert_that(subject.much_rails_call_callbacks_config.after_callbacks)
        .equals([proc2, proc1])

      # around_callbacks
      assert_that(
        subject.much_rails_call_callbacks_config.around_callbacks.size
      ).equals(0)

      subject.around_call(&proc1)
      assert_that(
        subject.much_rails_call_callbacks_config.around_callbacks.size
      ).equals(1)
      assert_that(subject.much_rails_call_callbacks_config.around_callbacks)
        .equals([proc1])

      subject.prepend_around_call(&proc2)
      assert_that(
        subject.much_rails_call_callbacks_config.around_callbacks.size
      ).equals(2)
      assert_that(subject.much_rails_call_callbacks_config.around_callbacks)
        .equals([proc2, proc1])
    end
  end

  class CallMethodTests < ReceiverTests
    desc "#call"
    subject { receiver_class }

    setup do
      subject.before_call do
        @values << "before 2"
        true
      end
      subject.prepend_before_call do
        @values << "before 1"
        true
      end
      subject.around_call do |receiver|
        @values << "start around 2"
        receiver.call
        @values << "end around 2"
        true
      end
      subject.prepend_around_call do |receiver|
        @values << "start around 1"
        receiver.call
        @values << "end around 1"
        true
      end
      subject.after_call do
        @values << "after 2"
        true
      end
      subject.prepend_after_call do
        @values << "after 1"
        true
      end

      subject.class_eval {
        def on_call
          @values << "on call"
          self
        end
      }
    end

    should "execute its callbacks" do
      return_value = subject.call

      assert_that(return_value).is_instance_of(receiver_class)
      assert_that(return_value.values)
        .equals([
          "before 1",
          "before 2",
          "start around 1",
          "start around 2",
          "on call",
          "end around 2",
          "end around 1",
          "after 1",
          "after 2"
        ])
    end
  end

  class MuchRailsCallCallbacksConfigTests < UnitTests
    desc "unit_class::MuchRailsCallCallbacksConfig"
    subject { config_class.new }

    let(:config_class) { unit_class::MuchRailsCallCallbacksConfig }

    should have_accessors :before_callbacks, :after_callbacks, :around_callbacks

    should "know its attribute values" do
      assert_that(subject.before_callbacks).equals([])
      assert_that(subject.after_callbacks).equals([])
      assert_that(subject.around_callbacks).equals([])
    end
  end
end
