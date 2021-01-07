# frozen_string_literal: true

require "much-rails"

module MuchRails; end

module MuchRails::Time
  InvalidError = Class.new(TypeError)

  # @example
  #   MuchRails::Time(nil) # => nil
  #   MuchRails::Time(" ") # => nil
  #   MuchRails::Time(Time.current) # => Time
  #   MuchRails::Time(DateTime.current) # => Time
  #   MuchRails::Time(Date.zone.today) # => Time
  #   MuchRails::Time("2020-07-04T08:15:00Z") # => Time
  def self.for(value)
    return if value.blank?

    if value.respond_to?(:to_time) && !value.is_a?(::String)
      value.to_time.utc
    else
      ::Time.iso8601(value.to_s).utc
    end
  rescue
    raise MuchRails::Time::InvalidError, "Invalid Time: #{value.inspect}."
  end
end
