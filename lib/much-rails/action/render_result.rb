# frozen_string_literal: true

require "much-rails/action/base_result"

# MuchRails::Action::RenderResult is a result returned by calling a view
# action that directs the controller to render a response.
module MuchRails; end
module MuchRails::Action; end
class MuchRails::Action::RenderResult < MuchRails::Action::BaseResult
  attr_reader :render_view_model, :render_kargs

  def initialize(render_view_model, **render_kargs)
    @render_view_model = render_view_model
    @render_kargs = render_kargs
  end

  # This block is called using `instance_exec` in the scope of the controller
  def execute_block
    ->(result) {
      @view_model = result.render_view_model
      render(**result.render_kargs)
    }
  end
end
