# frozen_string_literal: true

require "assert"
require "much-rails/call_method_callbacks"

module MuchRails::CallMethodCallbacks
  class UnitTests < Assert::Context
    desc "MuchRails::SaveService"
    subject{ unit_class }

    let(:unit_class){ MuchRails::CallMethodCallbacks }

    should "include MuchRails::Mixin" do
      assert_that(subject).includes(MuchRails::Mixin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject{ receiver_class }

    let(:receiver_class) do
      Class.new do
        include MuchRails::CallMethodCallbacks

        attr_reader :values

        def initialize
          @values = []
        end
      end
    end

    let(:proc1){ ->{} }
    let(:proc2){ ->{} }
    let(:proc3){ ->{} }

    should have_imeths :before_call, :prepend_before_call, :after_call
    should have_imeths :prepend_after_call, :around_call, :prepend_around_call
    should have_imeths :call

    should "be configured as expected" do
      assert_that(subject).includes(MuchRails::CallMethod)
      assert_that(subject).includes(MuchRails::Config)
    end

    should "know its attributes" do
      # before_callbacks
      subject.before_call(&proc1)

      assert_that{ subject.before_call(&proc2) }
        .changes(
          "subject.much_rails_call_callbacks_config.before_callbacks.dup",
          from: [proc1],
          to: [proc1, proc2],
        )

      assert_that{ subject.prepend_before_call(&proc3) }
        .changes(
          "subject.much_rails_call_callbacks_config.before_callbacks.dup",
          from: [proc1, proc2],
          to: [proc3, proc1, proc2],
        )

      # after_callbacks
      subject.after_call(&proc1)

      assert_that{ subject.after_call(&proc2) }
        .changes(
          "subject.much_rails_call_callbacks_config.after_callbacks.dup",
          from: [proc1],
          to: [proc1, proc2],
        )

      assert_that{ subject.prepend_after_call(&proc3) }
        .changes(
          "subject.much_rails_call_callbacks_config.after_callbacks.dup",
          from: [proc1, proc2],
          to: [proc3, proc1, proc2],
        )

      # around_callbacks
      subject.around_call(&proc1)

      assert_that{ subject.around_call(&proc2) }
        .changes(
          "subject.much_rails_call_callbacks_config.around_callbacks.dup",
          from: [proc1],
          to: [proc1, proc2],
        )

      assert_that{ subject.prepend_around_call(&proc3) }
        .changes(
          "subject.much_rails_call_callbacks_config.around_callbacks.dup",
          from: [proc1, proc2],
          to: [proc3, proc1, proc2],
        )
    end
  end

  class CallMethodTests < ReceiverTests
    desc "#call"
    subject{ receiver_class }

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

      subject.class_eval do
        def on_call
          @values << "on call"
          self
        end
      end
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
          "after 2",
        ])
    end
  end

  class MuchRailsCallCallbacksConfigTests < UnitTests
    desc "unit_class::MuchRailsCallCallbacksConfig"
    subject{ config_class.new }

    let(:config_class){ unit_class::MuchRailsCallCallbacksConfig }

    should have_accessors :before_callbacks, :after_callbacks, :around_callbacks

    should "know its attribute values" do
      assert_that(subject.before_callbacks).equals([])
      assert_that(subject.after_callbacks).equals([])
      assert_that(subject.around_callbacks).equals([])
    end
  end
end
