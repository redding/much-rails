# frozen_string_literal: true

module MuchRails; end

class MuchRails::ServiceValidationErrors
  attr_reader :hash

  def initialize
    @hash = {}
  end

  def add(exception_class, &block)
    unless exception_class < Exception
      raise(ArgumentError, "#{exception_class} is not an Exception")
    end

    @hash[exception_class] = block
  end

  def exception_classes
    @hash.keys
  end

  def result_for(ex)
    result_proc = nil
    exception_class = ex.class
    loop do
      result_proc = @hash[exception_class]
      break unless result_proc.nil?

      exception_class =
        if exception_class.superclass.nil?
          raise ArgumentError, "#{ex.class} hasn't been configured"
        else
          exception_class.superclass
        end
    end

    result_proc.call(ex)
  end
end
