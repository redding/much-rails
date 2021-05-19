# frozen_string_literal: true

module MuchRails; end

# MuchRails::InvalidError allows for raising and auto-rescueing general
# validation errors outside the scope of e.g. an ActiveRecord save.
class MuchRails::InvalidError < StandardError
  attr_reader :errors

  def initialize(backtrace: nil, **errors)
    @errors = errors

    super(@errors.inspect)
    set_backtrace(backtrace) if backtrace
  end

  def error_messages
    @errors.to_a.map do |(field_name, message)|
      "#{field_name}: #{Array.wrap(message).to_sentence}"
    end
  end
end
