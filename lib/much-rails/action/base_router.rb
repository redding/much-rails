# frozen_string_literal: true

module MuchRails; end
module MuchRails::Action; end

class MuchRails::Action::BaseRouter
  DEFAULT_BASE_URL = "/"

  # Override as needed.
  def self.url_class
    MuchRails::Action::BaseRouter::BaseURL
  end

  attr_reader :name
  attr_reader :request_type_set, :url_set, :routes, :definitions

  def initialize(name = nil, &block)
    @name = name
    @request_type_set = RequestTypeSet.new
    @url_set = URLSet.new(self)
    @routes, @definitions = [], []

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
  #   MyRouter =
  #     MuchRails::Action::Router.new {
  #       request_type(:mobile) do |request|
  #         mobile_user_agent?(request.user_agent)
  #       end
  #
  #       url :root, "/"
  #       get :root, "Root::Index",
  #                  mobile: "Root::IndexMobile"
  #     }
  def request_type(name, &constraints_lambda)
    @request_type_set.add(name, constraints_lambda)
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

  class RequestTypeSet
    def initialize
      @set = {}
    end

    def empty?
      @set.empty?
    end

    def add(name, constraints_lambda)
      request_type = RequestType.new(name.to_sym, constraints_lambda)
      key = request_type.name
      if !@set[key].nil?
        raise(
          ArgumentError,
          "There is already a request type named `#{name.to_sym.inspect}`."
        )
      end
      @set[key] = request_type
    end
  end

  class RequestType
    attr_reader :name, :constraints_lambda

    def initialize(name, constraints_lambda)
      @name = name.to_sym
      @constraints_lambda = constraints_lambda
    end
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
      url = @router.url_class.new(@router, path, name.to_sym)
      key = url.name
      if !@set[key].nil?
        raise ArgumentError, "There is already a URL named `#{name.to_sym.inspect}`."
      end
      @set[key] = url
    end

    def get(name)
      key = @router.url_class.url_name(@router, name.to_sym)
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
    def self.url_name(router, name)
      return unless name
      return name unless router&.name
      "#{router.name}_#{name}".to_sym
    end

    def self.url_path(router, path)
      return unless path
      return path unless router&.base_url
      File.join(router.base_url, path)
    end

    def self.for(router, url_or_path)
      return url_or_path if url_or_path.kind_of?(self)

      new(router, url_or_path)
    end

    attr_reader :router, :url_path, :url_name

    def initialize(router, url_path, url_name = nil)
      @router   = router
      @url_path = url_path.to_s
      @url_name = url_name&.to_sym
    end

    def name
      self.class.url_name(@router, @url_name)
    end

    def path
      self.class.url_path(@router, @url_path)
    end

    def path_for(*args)
      raise NotImplementedError
    end

    def url_for(*args)
      raise NotImplementedError
    end

    def ==(other_url)
      return super unless other_url.kind_of?(self.class)

      @router   == other_url.router &&
      @url_path == other_url.url_path &&
      @url_name == other_url.url_name
    end
  end
end
