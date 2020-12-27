# frozen_string_literal: true

require "much-rails"

module MuchRails; end
module MuchRails::Date
  InvalidError = Class.new(TypeError)

  # @example
  #   MuchRails::Date.for(nil) # => nil
  #   MuchRails::Date.for(" ") # => nil
  #   MuchRails::Date.for(Time.zone.today) # => Date
  #   MuchRails::Date.for(Time.current) # => Date
  #   MuchRails::Date.for(DateTime.current) # => Date
  #   MuchRails::Date.for("07/04/2020") # => Date
  #   MuchRails::Date.for("2020.07.04") # => Date
  #   MuchRails::Date.for("2020-07-04T08:15:00Z") # => Date
  def self.for(value)
    return if value.blank?

    if value.respond_to?(:to_date) && !value.is_a?(::String)
      value.to_date
    else
      self.parse(value)
    end
  rescue
    raise MuchRails::Date::InvalidError, "Invalid Date: #{value.inspect}."
  end

  def self.parse(value)
    parse_united_states(value)
  rescue ArgumentError
    parse8601(value)
  end

  def self.parse_united_states(value)
    formatted_value = value.to_s.gsub(/[^\w\s:]/, "-")

    ::Date.strptime(formatted_value, "%m-%d-%Y")
  rescue ArgumentError
    ::Date.strptime(formatted_value, "%Y-%m-%d")
  end

  def self.parse8601(value)
    formatted_value = value.to_s.gsub(/[^\w\s:]/, "-")

    ::Date.iso8601(formatted_value)
  rescue ArgumentError
    ::Time.iso8601(formatted_value).utc.to_date
  end
end
