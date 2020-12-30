# frozen_string_literal: true

require "much-rails"

module MuchRails; end
module MuchRails::ViewModels; end
MuchRails::ViewModels::Breadcrumb =
  Struct.new(:name, :url) do
    def render_as_link?
      url.present?
    end
  end
