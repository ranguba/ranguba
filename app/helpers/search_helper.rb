module SearchHelper
  def file_type_icon(type)
    image_tag "filetypes/#{type}.png",
              :alt => Ranguba::Customize.type(type),
              :size => "32x32"
  end
end
