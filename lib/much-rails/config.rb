# frozen_string_literal: true

require "much-rails/plugin"

module MuchRails; end

# MuchRails::Config is a mix-in to implement object DSL configuration.
module MuchRails::Config
  include MuchRails::Plugin

  plugin_class_methods do
    def add_config(name = nil, method_name: nil)
      config_method_name, config_class_name, configure_method_name =
        much_rails_config_names(name, method_name)

      instance_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        def #{config_method_name}
          @#{config_method_name} ||= self::#{config_class_name}.new
        end

        def #{configure_method_name}
          yield(#{config_method_name}) if block_given?
        end
      RUBY
    end

    def add_instance_config(name = nil, method_name: nil)
      config_method_name, config_class_name, configure_method_name =
        much_rails_config_names(name, method_name)

      instance_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        define_method(:#{config_method_name}) do
          @#{config_method_name} ||= self.class::#{config_class_name}.new
        end

        define_method(:#{configure_method_name}) do |&block|
          block.call(#{config_method_name}) if block
        end
      RUBY
    end

    private

    def much_rails_config_names(name, method_name)
      name_prefix = name.nil? ? "" : "#{name.to_s.underscore}_"
      config_method_name = (method_name || "#{name_prefix}config").to_s
      config_class_name = "#{name_prefix.classify}Config"

      name_suffix = name.nil? ? "" : "_#{name.to_s.underscore}"
      configure_method_name = "configure#{name_suffix}"

      [config_method_name, config_class_name, configure_method_name]
    end
  end
end
