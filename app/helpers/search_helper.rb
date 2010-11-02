module SearchHelper
  def filetype_icon(type)
    image_tag "filetypes/#{type}.png",
              :alt => Ranguba::Customize.type(type),
              :size => "24x24"
  end
end
