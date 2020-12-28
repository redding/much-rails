require "assert"
require "much-rails/wrap_and_call_method"

module MuchRails::WrapAndCallMethod
  class UnitTests < Assert::Context
    desc "MuchRails::WrapAndCallMethod"
    subject { unit_class }

    let(:unit_class) { MuchRails::WrapAndCallMethod }

    should "include MuchPlugin" do
      assert_that(subject).includes(MuchPlugin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject { receiver_class }

    let(:receiver_class) {
      Class.new do
        include MuchRails::WrapAndCallMethod

        attr_reader :object, :object_kargs, :call_called

        def initialize(object, **object_kargs)
          @object = object
          @object_kargs = object_kargs
        end

        def call
          @call_called = true
          MuchResult.success(name: object.name)
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

    should have_imeths :wrap_and_call, :wrap_and_map_call
    should have_imeths :wrap_and_capture_call, :wrap_and_capture_call!

    should "be configured as expected" do
      assert_that(subject).includes(MuchRails::CallMethod)
      assert_that(subject).includes(MuchRails::WrapMethod)
    end
  end

  class WrapAndCallTests < ReceiverTests
    desc "wrap and call"
    subject { receiver_class }

    should "wrap and call its objects and return the wrapped objects" do
      wrapped_objects = subject.wrap_and_call(objects, **object_kargs)

      assert_that(wrapped_objects.size).equals(objects.size)
      wrapped_objects.each_with_index do |wrapped_object, index|
        assert_that(wrapped_object).is_instance_of(subject)
        assert_that(wrapped_object.object).equals(objects[index])
        assert_that(wrapped_object.object_kargs).equals(object_kargs)
        assert_that(wrapped_object.call_called).is_true
      end
    end
  end

  class WrapAndMapCallTests < ReceiverTests
    desc "wrap and map call"
    subject { receiver_class }

    should "wrap and call its object and return each call's return value" do
      wrapped_objects = subject.wrap_and_call(objects, **object_kargs)
      call_results = subject.wrap_and_map_call(objects, **object_kargs)

      assert_that(call_results.size).equals(objects.size)
      call_results.each_with_index do |result, index|
        assert_that(result.name).equals(wrapped_objects[index].call.name)
      end
    end
  end

  class WrapAndCaptureCallTests < ReceiverTests
    desc "wrap and capture call"
    subject { receiver_class }

    setup do
      Assert.stub(MuchResult, :tap) { |&block| block.call(tapped_result1) }
      Assert.stub_tap_on_call(tapped_result1, :capture_for_all) { |_, call|
        @capture_for_all_call = call
      }
    end

    let(:tapped_result1) { MuchResult.success }

    should "wrap and call its objects and capture each return value as a "\
           "sub-result in a given MuchResult" do
      wrapped_objects = subject.wrap_and_call(objects, **object_kargs)

      MuchResult.tap { |result|
        subject.wrap_and_capture_call(
          objects,
          capturing_result: result,
          **object_kargs)
      }

      assert_that(tapped_result1.sub_results.size).equals(objects.size)
      tapped_result1.sub_results.each_with_index do |sub_result, index|
        assert_that(sub_result.name).equals(wrapped_objects[index].call.name)
      end
      assert_that(@capture_for_all_call.args)
        .equals([tapped_result1.sub_results])
    end
  end

  class WrapAndCaptureCallBangTests < ReceiverTests
    desc "wrap and capture call bang"
    subject { receiver_class }

    setup do
      Assert.stub(MuchResult, :tap) { |&block| block.call(tapped_result1) }
      Assert.stub_tap_on_call(tapped_result1, :capture_for_all!) { |_, call|
        @capture_for_all_bang_call = call
      }
    end

    let(:tapped_result1) { MuchResult.success }

    should "wrap and call its objects and capture each return value as a "\
           "sub-result in a given MuchResult" do
      wrapped_objects = subject.wrap_and_call(objects, **object_kargs)

      MuchResult.tap { |result|
        subject.wrap_and_capture_call!(
          objects,
          capturing_result: result,
          **object_kargs)
      }

      assert_that(tapped_result1.sub_results.size).equals(objects.size)
      tapped_result1.sub_results.each_with_index do |sub_result, index|
        assert_that(sub_result.name).equals(wrapped_objects[index].call.name)
      end
      assert_that(@capture_for_all_bang_call.args)
        .equals([tapped_result1.sub_results])
    end
  end
end
