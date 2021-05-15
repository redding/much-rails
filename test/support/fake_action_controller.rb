# frozen_string_literal: true

require "much-rails/mixin"

module FakeActionController
  include MuchRails::Mixin

  after_mixin_included do
    include MuchRails::Action::Controller

    attr_reader :params
    attr_reader :head_called_with, :render_called_with
  end

  mixin_class_methods do
    def before_action(*args, &block)
      before_action_calls << Assert::StubCall.new(*args, &block)
    end

    def prepend_before_action(*args, &block)
      prepend_before_action_calls << Assert::StubCall.new(*args, &block)
    end

    def before_action_calls
      @before_action_calls ||= []
    end

    def prepend_before_action_calls
      @prepend_before_action_calls ||= []
    end
  end

  mixin_instance_methods do
    def initialize(params)
      @params = FakeParams.new(params)
      self.class.prepend_before_action_calls.each do |before_action_call|
        public_send(before_action_call.args.first)
      end
      self.class.before_action_calls.each do |before_action_call|
        public_send(before_action_call.args.first)
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
