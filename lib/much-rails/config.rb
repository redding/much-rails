require "much-rails"
require "much-plugin"

# MuchRails::Config is a mix-in to implement object DSL configuration.
module MuchRails; end
module MuchRails::Config
  include MuchPlugin

  after_plugin_included do
    add_config
  end

  plugin_class_methods do
    def add_config(name = nil)
      name_prefix = name.nil? ? "" : "#{name.to_s.underscore}_"
      config_method_name = "#{name_prefix}config"
      config_class_name = "#{name_prefix.classify}Config"

      name_suffix = name.nil? ? "" : "_#{name.to_s.underscore}"
      configure_method_name = "configure#{name_suffix}"

      instance_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        def #{config_method_name}
          @#{config_method_name} ||= self::#{config_class_name}.new
        end

        def #{configure_method_name}
          yield(#{config_method_name}) if block_given?
        end
      RUBY
    end
  end
end
