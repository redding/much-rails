# frozen_string_literal: true

require "assert"
require "much-rails/wrap_method"

module MuchRails::WrapMethod
  class UnitTests < Assert::Context
    desc "MuchRails::WrapMethod"
    subject { unit_class }

    let(:unit_class) { MuchRails::WrapMethod }

    should "include MuchRails::Plugin" do
      assert_that(subject).includes(MuchRails::Plugin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject { receiver_class }

    let(:receiver_class) {
      Class.new do
        include MuchRails::WrapMethod

        attr_reader :object, :object_kargs

        def initialize(object, **object_kargs)
          @object = object
          @object_kargs = object_kargs
        end

        def self.build(object, **object_kargs)
          new(object, initializer_method: :build, **object_kargs)
        end
      end
    }

    let(:objects) { [object1, object2] }
    let(:object1) { OpenStruct.new(name: "OBJECT1") }
    let(:object2) { OpenStruct.new(name: "OBJECT2") }

    let(:object_kargs) {
      {
        test_key1: 1,
        test_key2: 2
      }
    }

    should have_imeths :wrap, :wrap_with_index, :wrap_initializer_method
  end

  class WrapAndWrapWithIndexTests < ReceiverTests
    desc "wrap and wrap with index"
    subject { receiver_class }

    should "call new for each given object" do
      wrapped_objects = subject.wrap(objects, **object_kargs)

      assert_that(wrapped_objects.size).equals(objects.size)
      wrapped_objects.each_with_index do |wrapped_object, index|
        assert_that(wrapped_object).is_instance_of(subject)
        assert_that(wrapped_object.object).equals(objects[index])
        assert_that(wrapped_object.object_kargs).equals(object_kargs)
      end

      wrapped_objects = subject.wrap_with_index(objects, **object_kargs)

      assert_that(wrapped_objects.size).equals(objects.size)
      wrapped_objects.each_with_index do |wrapped_object, index|
        assert_that(wrapped_object).is_instance_of(subject)
        assert_that(wrapped_object.object).equals(objects[index])
        assert_that(wrapped_object.object_kargs)
          .equals(object_kargs.update(index: index))
      end
    end
  end

  class CustomWrapInitializerMethodTests < ReceiverTests
    desc "with a custom wrap initializer method"
    subject { receiver_class }

    setup do
      receiver_class.wrap_initializer_method(:build)
    end

    should "call the custom method for each given object" do
      wrapped_objects = subject.wrap(objects, **object_kargs)

      assert_that(wrapped_objects.size).equals(objects.size)
      wrapped_objects.each_with_index do |wrapped_object, index|
        assert_that(wrapped_object).is_instance_of(subject)
        assert_that(wrapped_object.object).equals(objects[index])
        assert_that(wrapped_object.object_kargs)
          .equals(object_kargs.merge(initializer_method: :build))
      end
    end
  end

  class WrapMethodConfigTests < ReceiverTests
    desc "receiver_class::WrapMethodConfig"
    subject { config_class.new }

    let(:config_class) { receiver_class::WrapMethodConfig }

    should have_accessors :wrap_initializer_method

    should "know its attribute values" do
      assert_that(subject.wrap_initializer_method).equals(:new)
    end
  end
end
