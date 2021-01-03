require "assert"
require "much-rails"

module MuchRails
  class UnitTests < Assert::Context
    desc "MuchRails"
    subject { unit_class }

    let(:unit_class) { MuchRails }

    should have_imeths :config, :configure_much_rails, :configure

    should "be configured as expected" do
      assert_that(subject).includes(MuchRails::Config)
      assert_that(subject).includes(MuchRails::NotGiven)
      assert_that(subject.config).is_not_nil
    end
  end

  class ConfigTests < UnitTests
    desc ".config"
    subject { unit_class.config }

    should have_imeths :action

    should "be configured as expected" do
      assert_that(subject.action).is_not_nil
    end
  end

  class ActionConfigTests < UnitTests
    desc ".action"
    subject { unit_class.config.action }

    should have_accessors :namespace
    should have_accessors :sanitized_exception_classes
    should have_accessors :raise_response_exceptions

    should have_imeths :raise_response_exceptions?

    should "be configured as expected" do
      assert_that(subject.namespace).equals("")
      assert_that(subject.sanitized_exception_classes)
        .equals([ActiveRecord::RecordInvalid])
      assert_that(subject.raise_response_exceptions).is_false
      assert_that(subject.raise_response_exceptions?).is_false
    end
  end
end
