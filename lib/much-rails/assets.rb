# frozen_string_literal: true

require "dassets"
require "dassets/server"
require "dassets-erubi"
require "dassets-sass"

module MuchRails
  Assets = Dassets
end

module MuchRails::Assets
  def self.configure_for_rails(rails)
    MuchRails::Assets.configure do |config|
      # Cache fingerprints in memory for performance gains.
      config.fingerprint_cache MuchRails::Assets::MemCache.new

      # Cache compiled content in memory in development/test for performance
      # gains since we aren't caching to the file system. Otherwise, don't
      # cache in memory as we are caching to the file system and won't benefit
      # from the in memory cache.
      much_rails_content_cache =
        if rails.env.development? || rails.env.test?
          MuchRails::Assets::MemCache.new
        else
          MuchRails::Assets::NoCache.new
        end
      config.content_cache much_rails_content_cache

      # Cache out compiled file content to the public folder in non
      # development/test environments.
      if !rails.env.development? && !rails.env.test?
        config.file_store rails.root.join("public")
      end

      # Look for asset files in the app/assets/css folder. Support ERB
      # on all .scss files. Support compilation of .scss files.
      config.source rails.root.join("app", "assets", "css") do |s|
        s.base_path "css"

        # Reject SCSS partials
        s.filter do |paths|
          paths.reject{ |p| File.basename(p) =~ /^_.*\.scss$/ }
        end

        s.engine "scss", MuchRails::Assets::Erubi::Engine
        s.engine "scss", MuchRails::Assets::Sass::Engine, {
          syntax: "scss",
          output_style: "compressed",
        }
      end

      # Look for asset files in the app/assets/img folder.
      config.source rails.root.join("app", "assets", "img") do |s|
        s.base_path "img"
      end

      # Look for asset files in the app/assets/js folder. Support ERB
      # on all .js files.
      config.source rails.root.join("app", "assets", "js") do |s|
        s.base_path "js"

        s.engine "js", MuchRails::Assets::Erubi::Engine
      end

      # Look for asset files in the app/assets/vendor folder
      config.source rails.root.join("app", "assets", "vendor") do |s|
        s.base_path "vendor"
      end
    end
    MuchRails::Assets.init
  end
end
