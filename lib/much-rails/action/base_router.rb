# frozen_string_literal: true

require "set"

module MuchRails; end
module MuchRails::Action; end

class MuchRails::Action::BaseRouter
  DEFAULT_BASE_URL = "/"

  # Override as needed.
  def self.url_class
    MuchRails::Action::BaseRouter::BaseURL
  end

  attr_reader :name
  attr_reader :url_set, :request_types, :routes, :definitions

  def initialize(name = nil, &block)
    @name = name
    @url_set = URLSet.new(self)
    @request_types, @routes, @definitions = [], [], []

    @base_url = DEFAULT_BASE_URL
  end

  def url_class
    self.class.url_class
  end

  def apply_to(to_scope)
    raise NotImplementedError
  end

  # Example:
  #   MyRouter =
  #     MuchRails::Action::Router.new {
  #       url :root, "/", "Root"
  #     }
  #   MyRouter.path_for(:root) # => "/"
  #
  #   AdminRouter =
  #     MuchRails::Action::Router.new(:admin) {
  #       base_url "/admin"
  #       url :users, "/users", "Users::Index"
  #     }
  #   AdminRouter.path_for(:users) # => "/admin/users"
  def path_for(name, *args)
    @url_set.path_for(name, *args)
  end

  # Example:
  #   MyRouter =
  #     MuchRails::Action::Router.new {
  #       url :root, "/", "Root"
  #     }
  #   MyRouter.url_for(:root) # => "http://example.org/"
  #
  #   AdminRouter =
  #     MuchRails::Action::Router.new(:admin) {
  #       base_url "/admin"
  #       url :users, "/users", "Users::Index"
  #     }
  #   AdminRouter.url_for(:users) # => "http://example.org/admin/users"
  def url_for(name, *args)
    @url_set.url_for(name, *args)
  end

  # Example:
  #   AdminRouter =
  #     MuchRails::Action::Router.new(:admin) {
  #       base_url "/admin"
  #       url :users, "/users", "Users::Index"
  #     }
  #   AdminRouter.path_for(:users) # => "/admin/users"
  def base_url(value = nil)
    @base_url = value if !value.nil?
    @base_url
  end

  # Example:
  #   MyRouter =
  #     MuchRails::Action::Router.new {
  #       url :root, "/"
  #       get :root, "Root::Index"
  #     }
  def url(name, path)
    if !name.kind_of?(::Symbol)
      raise(
        ArgumentError,
        "Named URLs must be defined with Symbol names, given `#{name.inspect}`."
      )
    end
    if !path.kind_of?(::String)
      raise(
        ArgumentError,
        "Named URLs must be defined with String paths, given `#{path.inspect}`."
      )
    end
    @url_set.add(name, path)
  end

  class URLSet
    def initialize(router)
      @set = {}
      @router = router
    end

    def empty?
      @set.empty?
    end

    def add(name, path)
      url = @router.url_class.new(name.to_sym, path, @router)
      key = url.name
      if !@set[key].nil?
        raise ArgumentError, "There is already a URL named `#{name.to_sym.inspect}`."
      end
      @set[key] = url
    end

    def get(name)
      key = @router.url_class.url_name(name.to_sym, @router)
      @set.fetch(key) {
        raise ArgumentError, "There is no URL named `#{name.to_sym.inspect}`."
      }
    end

    def path_for(name, *args)
      get(name).path_for(*args)
    end

    def url_for(name, *args)
      get(name).url_for(*args)
    end
  end

  class BaseURL
    def self.url_name(name, router)
      return unless name
      return name unless router&.name
      "#{router.name}_#{name}".to_sym
    end

    def self.url_path(path, router)
      return unless path
      return path unless router&.base_url
      File.join(router.base_url, path)
    end

    def initialize(url_name, url_path, router)
      @url_name = url_name.to_sym
      @url_path = url_path.to_s
      @router   = router
    end

    def name
      self.class.url_name(@url_name, @router)
    end

    def path
      self.class.url_path(@url_path, @router)
    end

    def path_for(*args)
      raise NotImplementedError
    end

    def url_for(*args)
      raise NotImplementedError
    end
  end
end
