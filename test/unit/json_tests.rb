# frozen_string_literal: true

require "assert"
require "much-rails/json"

module MuchRails::JSON
  class UnitTests < Assert::Context
    desc "MuchRails::JSON"
    subject{ unit_class }

    let(:unit_class){ MuchRails::JSON }

    let(:object){ { some_key: "SOME VALUE" } }

    should have_imeths :default_mode, :encode, :decode

    should "know its attributes" do
      # default_mode
      assert_that(subject.default_mode).equals(:strict)

      # encode
      assert_that(subject.encode(object))
        .equals(Oj.dump(object, mode: subject.default_mode))

      options = { ascii_only: true }
      assert_that(subject.encode(object, **options))
        .equals(Oj.dump(object, mode: subject.default_mode, **options))

      time_object = { some_key: Time.now }
      mode = :null
      assert_that{ subject.encode(time_object) }.raises(TypeError)
      assert_that(subject.encode(time_object, mode: mode))
        .equals(Oj.dump(time_object, mode: mode))

      # decode
      encoded_object = subject.encode(object)
      assert_that(subject.decode(encoded_object))
        .equals(Oj.load(encoded_object, mode: subject.default_mode))

      numeric_object = { some_key: 1.25 }
      options = { bigdecimal_load: :bigdecimal }
      encoded_object = subject.encode(numeric_object)
      decoded_object = subject.decode(encoded_object, **options)
      assert_that(decoded_object)
        .equals(Oj.load(encoded_object, mode: subject.default_mode, **options))
      assert_that(decoded_object["some_key"].class).equals(BigDecimal)

      encoded_object = "some-rando-string-that-isnt-JSON"
      ex =
        assert_that{ subject.decode(encoded_object) }
          .raises(unit_class::InvalidError)
      assert_that(ex.message).includes("Oj::ParseError")
    end
  end
end
