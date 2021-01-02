require "assert"
require "much-rails/config"

module MuchRails::Config
  class UnitTests < Assert::Context
    desc "MuchRails::Config"
    subject { unit_class }

    let(:unit_class) { MuchRails::Config }

    should "include MuchRails::Plugin" do
      assert_that(subject).includes(MuchRails::Plugin)
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
        include MuchRails::Config

        add_instance_config :sub, method_name: :sub

        attr_accessor :another_value

        class SubConfig
          attr_accessor :sub_value
        end
      end
    end

    let(:receiver_class) {
      Class.new do
        include MuchRails::Config

        add_config
        add_config :another
      end
    }

    should have_imeths :config, :another_config

    should "know its attributes" do
      assert_that(subject.config).is_instance_of(subject::Config)
      subject.configure { |config| config.value = "VALUE 1" }
      assert_that(subject.config.value).equals("VALUE 1")

      assert_that(subject.another_config).is_instance_of(subject::AnotherConfig)
      subject.configure_another { |config| config.another_value = "VALUE 2" }
      assert_that(subject.another_config.another_value).equals("VALUE 2")

      assert_that(subject.another_config.sub)
        .is_instance_of(subject::AnotherConfig::SubConfig)
      subject.another_config.configure_sub { |sub|
        sub.sub_value = "VALUE 3"
      }
      assert_that(subject.another_config.sub.sub_value).equals("VALUE 3")
    end
  end
end
