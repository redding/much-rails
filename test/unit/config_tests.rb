require "assert"
require "much-rails/config"

module MuchRails::Config
  class UnitTests < Assert::Context
    desc "MuchRails::Config"
    subject { unit_class }

    let(:unit_class) { MuchRails::Config }

    should "include MuchPlugin" do
      assert_that(subject).includes(MuchPlugin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject { receiver_class }

    setup do
      class receiver_class::Config
        attr_accessor :value
      end

      class receiver_class::AnotherConfig
        attr_accessor :another_value
      end
    end

    let(:receiver_class) {
      Class.new do
        include MuchRails::Config

        add_config :another
      end
    }

    should have_imeths :config, :another_config

    should "know its attributes" do
      assert_that(subject.config).is_instance_of(subject::Config)
      subject.configure { |config| config.value = "VALUE1" }
      assert_that(subject.config.value).equals("VALUE1")

      assert_that(subject.another_config).is_instance_of(subject::AnotherConfig)
      subject.configure_another { |config| config.another_value = "VALUE2" }
      assert_that(subject.another_config.another_value).equals("VALUE2")
    end
  end
end
