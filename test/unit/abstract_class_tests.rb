# frozen_string_literal: true

require "assert"
require "much-rails/abstract_class"

module MuchRails::AbstractClassTest
  class UnitTests < Assert::Context
    desc "MuchRails::AbstractClass"
    subject{ unit_class }

    let(:unit_class){ MuchRails::AbstractClass }

    should "include MuchRails::Mixin" do
      assert_that(subject).includes(MuchRails::Mixin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject{ receiver_class }

    let(:receiver_class) do
      Class.new.tap{ |c| c.include unit_class }
    end
    let(:receiver_subclass) do
      Class.new(receiver_class)
    end

    should have_accessor :abstract_class
    should have_imeths :new, :abstract_class?

    should "know if it is an abstract class or not" do
      assert_that(subject.abstract_class?).equals(true)
      assert_that(receiver_subclass.abstract_class?).equals(false)
    end

    should "prevent calling .new on the receiver" do
      assert_that{ subject.new }.raises(NotImplementedError)
    end

    should "allow calling .new on subclasses of the receiver" do
      assert_that(receiver_subclass.new).is_a?(subject)
    end
  end
end
