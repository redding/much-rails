# frozen_string_literal: true

require "much-rails"

# MuchRails::InputValue is a utility module for dealing with input field values.
module MuchRails;end
module MuchRails::InputValue
  def self.strip(value)
    return if value.blank?

    value.to_s.strip
  end

  def self.strip_all(values)
    Array
      .wrap(values)
      .map { |value| strip(value) }
      .compact
  end
end
