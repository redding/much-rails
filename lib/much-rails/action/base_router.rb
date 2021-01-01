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
  attr_reader :request_type_set, :url_set, :definitions

  def initialize(name = nil, &block)
    @name = name
    @request_type_set = RequestTypeSet.new
    @url_set = URLSet.new(self)
    @definitions = []
    @defined_urls = []

    @base_url = DEFAULT_BASE_URL
    instance_exec(&(block || proc{}))
  end

  def url_class
    self.class.url_class
  end

  def unrouted_urls
    @url_set.urls - @defined_urls
  end

  def validate!
    definitions.each do |definition|
      definition.request_type_actions.each do |request_type_action|
        begin
          request_type_action.class_name.constantize
        rescue NameError => ex
          raise(NameError, ex.message, definition.called_from, cause: ex)
        end
      end

      next unless definition.has_default_action_class_name?

      begin
        definition.default_action_class_name.constantize
      rescue NameError => ex
        raise(NameError, ex.message, definition.called_from, cause: ex)
      end
    end
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
    @base_url = value unless value.nil?
    @base_url
  end

  # Example:
  #   MyRouter =
  #     MuchRails::Action::Router.new {
  #       url :root, "/"
  #       get :root, "Root::Index"
  #     }
  def url(name, path)
    unless name.is_a?(::Symbol)
      raise(
        ArgumentError,
        "Named URLs must be defined with Symbol names, "\
        "given `#{name.inspect}`.",
      )
    end
    unless path.is_a?(::String)
      raise(
        ArgumentError,
        "Named URLs must be defined with String paths, "\
        "given `#{path.inspect}`.",
      )
    end
    @url_set.add(name, path)
  end

  # Example:
  #   MyRouter =
  #     MuchRails::Action::Router.new {
  #       get    "/",       "Root::Index"
  #       get    "/new",    "Root::New"
  #       post   "/",       "Root::Create"
  #       get    "/edit",   "Root::Edit"
  #       put    "/",       "Root::Update"
  #       patch  "/",       "Root::Update"
  #       get    "/remove", "Root::Remove"
  #       delete "/",       "Root::Destroy"
  #     }
  def get(
        path,
        default_class_name = nil,
        called_from: caller,
        **request_type_class_names)
    route(
      :get,
      path,
      default_class_name,
      called_from: called_from,
      **request_type_class_names,
    )
  end

  def post(
        path,
        default_class_name = nil,
        called_from: caller,
        **request_type_class_names)
    route(
      :post,
      path,
      default_class_name,
      called_from: called_from,
      **request_type_class_names,
    )
  end

  def put(
        path,
        default_class_name = nil,
        called_from: caller,
        **request_type_class_names)
    route(
      :put,
      path,
      default_class_name,
      called_from: called_from,
      **request_type_class_names,
    )
  end

  def patch(
        path,
        default_class_name = nil,
        called_from: caller,
        **request_type_class_names)
    route(
      :patch,
      path,
      default_class_name,
      called_from: called_from,
      **request_type_class_names,
    )
  end

  def delete(
        path,
        default_class_name = nil,
        called_from: caller,
        **request_type_class_names)
    route(
      :delete,
      path,
      default_class_name,
      called_from: called_from,
      **request_type_class_names,
    )
  end

  # TODO
  # Example:
  #   MyRouter =
  #     MuchRails::Action::Router.new {
  #       redirect "/", "/home"
  #       redirect "/old" do
  #         # in the scope of a MuchRails::RedirectAction
  #         params[:version] ? "/new-#{params[:version]}" : "new"
  #       end
  #     }
  # def redirect(from_path, to_path = nil, &block)
  #   self.definitions.push([:redirect, [from_path, to_path], block])
  # end

  # TODO
  # Example:
  #   MyRouter =
  #     MuchRails::Action::Router.new {
  #       not_found "/honeypot"
  #       not_found "/honeypot-alt" do
  #         "The resource couldn't be found on the server."
  #       end
  #     }
  # def not_found(from_path, &response_body_block)
  #   respond_with_args = [404, {}, response_body_block || -> { "Not Found" }]
  #   self.definitions.push([:respond_with, [from_path, respond_with_args], nil])
  # end

  private

  def route(
        http_method,
        url_name_or_path,
        default_class_name,
        called_from:,
        **request_type_class_names)
    url =
      @url_set.fetch(url_name_or_path){ url_class.for(self, url_name_or_path) }
    request_type_actions =
      request_type_class_names
        .reduce([]) do |acc, (request_type_name, action_class_name)|
          acc <<
            RequestTypeAction.new(
              request_type_set.get(request_type_name),
              action_class_name,
            )
          acc
        end

    add_definition(
      Definition.for_route(
        http_method: http_method,
        url: url,
        default_action_class_name: default_class_name,
        request_type_actions: request_type_actions,
        called_from: called_from,
      ),
    )
  end

  def add_definition(definition)
    @definitions << definition
    @defined_urls << definition.url

    definition
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
      unless @set[key].nil?
        raise(
          ArgumentError,
          "There is already a request type named `#{name.to_sym.inspect}`.",
        )
      end
      @set[key] = request_type
    end

    def get(name)
      key = name.to_sym
      @set.fetch(key) do
        raise(
          ArgumentError,
          "There is no request type named `#{name.to_sym.inspect}`.",
        )
      end
    end
  end

  RequestType = Struct.new(:name, :constraints_lambda)
  RequestTypeAction =
    Struct.new(:request_type, :class_name) do
      def constraints_lambda
        request_type.constraints_lambda
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

    def urls
      @set.values
    end

    def add(name, path)
      url = @router.url_class.new(@router, path, name.to_sym)
      key = url.name
      unless @set[key].nil?
        raise(
          ArgumentError,
          "There is already a URL named `#{name.to_sym.inspect}`.",
        )
      end

      @set[key] = url
    end

    def fetch(name, default_value = nil, &block)
      key = @router.url_class.url_name(@router, name.to_sym)
      if default_value
        @set.fetch(key, default_value)
      else
        @set.fetch(
          key,
          &(
            block ||
            proc{
              raise(
                ArgumentError,
                "There is no URL named `#{name.to_sym.inspect}`.",
              )
            }
          )
        )
      end
    end

    def path_for(name, *args)
      fetch(name).path_for(*args)
    end

    def url_for(name, *args)
      fetch(name).url_for(*args)
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
      return url_or_path if url_or_path.is_a?(self)

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

    def ==(other)
      return super unless other.is_a?(self.class)

      @router   == other.router &&
      @url_path == other.url_path &&
      @url_name == other.url_name
    end
  end

  class Definition
    def self.for_route(
          http_method:,
          url:,
          default_action_class_name:,
          request_type_actions:,
          called_from:)
      new(
        http_method: http_method,
        url: url,
        default_action_class_name: default_action_class_name,
        request_type_actions: request_type_actions,
        called_from: called_from,
      )
    end

    attr_reader :http_method, :url, :default_params
    attr_reader :default_action_class_name, :request_type_actions
    attr_reader :called_from

    def initialize(
          http_method:,
          url:,
          default_action_class_name:,
          request_type_actions:,
          called_from:,
          default_params: nil)
      @http_method = http_method
      @url = url
      @default_params = default_params || {}
      @default_action_class_name = default_action_class_name
      @request_type_actions = request_type_actions || []
      @called_from = called_from
    end

    def name
      @url.name
    end

    def path
      @url.path
    end

    def has_default_action_class_name?
      !@default_action_class_name.nil?
    end

    def ==(other)
      return super unless other.is_a?(self.class)

      @http_method == other.http_method &&
      @url == other.url &&
      @default_params == other.default_params &&
      @default_action_class_name ==
        other.default_action_class_name &&
      @request_type_actions == other.request_type_actions
    end
  end
end
