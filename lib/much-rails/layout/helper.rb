# frozen_string_literal: true

module MuchRails; end
module MuchRails::Layout; end

module MuchRails::Layout::Helper
  # This is used to render layouts. It is designed to be used in
  # the Rails layout template to render the nested layouts.
  def much_rails_render_layouts(view_model, &content)
    unless view_model.is_a?(MuchRails::Layout)
      raise(
        TypeError,
        "A View Model that mixes in MuchRails::Layout expected; "\
        "got #{view_model.class}.",
      )
    end
    view_model
      .layouts
      .reverse
      .reduce(content){ |render_proc, template_path|
        ->{ render(File.join("layouts", template_path), &render_proc) }
      }
      .call
  end
end
