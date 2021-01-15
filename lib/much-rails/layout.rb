# frozen_string_literal: true

require "much-rails/layout/helper"
require "much-rails/mixin"
require "much-rails/view_models/breadcrumb"

module MuchRails; end

# MuchRails::Layout is a mix-in for view models that represent HTML rendered
# in a layout. It adds a DSL for accumulating page titles, stylesheets and
# javascripts.
module MuchRails::Layout
  include MuchRails::Mixin

  mixin_class_methods do
    def page_title(&block)
      page_titles << block
    end

    def page_titles
      @page_titles ||= []
    end

    def application_page_title(&block)
      @application_page_title = block if block
      @application_page_title
    end

    def breadcrumb(&block)
      breadcrumbs << block
    end

    def breadcrumbs
      @breadcrumbs ||= []
    end

    def stylesheet(value = nil, &block)
      stylesheets << (block || ->{ value })
    end

    def stylesheets
      @stylesheets ||= []
    end

    def javascript(value = nil, &block)
      javascripts << (block || ->{ value })
    end

    def javascripts
      @javascripts ||= []
    end

    def head_link(url, **attributes)
      head_links << HeadLink.new(url, **attributes)
    end

    def head_links
      @head_links ||= []
    end

    def layout(value)
      layouts << value
    end

    def layouts
      @layouts ||= []
    end
  end

  mixin_instance_methods do
    def page_title
      @page_title ||= instance_eval(&(self.class.page_titles.last || ->(_){}))
    end

    def application_page_title
      @application_page_title ||=
        instance_eval(&(self.class.application_page_title || ->(_){}))
    end

    def full_page_title
      @full_page_title ||=
        [
          self
            .class
            .page_titles
            .reverse
            .map!{ |segment| instance_eval(&segment) }
            .join(MuchRails.config.layout.full_page_title_segment_separator),
          application_page_title,
        ]
          .map(&:presence)
          .compact
          .join(MuchRails.config.layout.full_page_title_application_separator)
          .presence
    end

    def breadcrumbs
      @breadcrumbs ||=
        self
          .class
          .breadcrumbs
          .map do |block|
            MuchRails::ViewModels::Breadcrumb.new(*instance_eval(&block))
          end
    end

    def stylesheets
      @stylesheets ||= self.class.stylesheets.map(&:call)
    end

    def javascripts
      @javascripts ||= self.class.javascripts.map(&:call)
    end

    def head_links
      @head_links ||= self.class.head_links
    end

    def layouts
      self.class.layouts
    end

    def any_breadcrumbs?
      breadcrumbs.any?
    end
  end

  class HeadLink
    attr_reader :href, :attributes

    def initialize(href, **attributes)
      @href = href
      @attributes = attributes
    end

    def ==(other)
      super unless other.is_a?(self.class)

      href == other.href && attributes == other.attributes
    end
  end
end
