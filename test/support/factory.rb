require "assert/factory"

module Factory
  extend Assert::Factory

  # TODO: add to MuchFactory
  def self.symbol(*args)
    string(*args).to_sym
  end
end
