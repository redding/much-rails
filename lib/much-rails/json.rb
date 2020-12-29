# frozen_string_literal: true

require "oj"

# MuchRails::JSON is an adapter for encoding and decoding JSON values.
# It uses Oj to do the work: https://github.com/ohler55/oj#-gem
module MuchRails; end
module MuchRails::JSON
  InvalidError = Class.new(TypeError)

  def self.default_mode
    :strict
  end

  def self.encode(obj, **options)
    options[:mode] ||= default_mode
    ::Oj.dump(obj, options)
  end

  def self.decode(json, **options)
    options[:mode] ||= default_mode
    ::Oj.load(json, options)
  rescue ::Oj::ParseError => ex
    error = InvalidError.new("Oj::ParseError: #{ex.message}")
    error.set_backtrace(ex.backtrace)
    raise error
  end
end
