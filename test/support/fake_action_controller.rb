require "much-rails/plugin"

module FakeActionController
  include MuchRails::Plugin

  after_plugin_included do
    include MuchRails::Action::Controller

    attr_reader :params
    attr_reader :head_called_with, :render_called_with
  end

  plugin_class_methods do
    def before_action(method_name)
      before_actions << method_name
    end

    def before_actions
      @before_actions ||= []
    end
  end

  plugin_instance_methods do
    def initialize(params)
      @params = FakeParams.new(params)
      self.class.before_actions.each do |before_action|
        self.public_send(before_action)
      end
    end

    def head(*args)
      @head_called_with = args
      self
    end

    def render(**kargs)
      @render_called_with = kargs
    end
  end

  class FakeParams
    def initialize(params)
      @params = params
    end

    def permit!
      @permit_called = true
      self
    end

    def [](key)
      @params[key]
    end

    def to_h
      raise "params haven't been permitted" unless @permit_called
      @params
    end
  end
end