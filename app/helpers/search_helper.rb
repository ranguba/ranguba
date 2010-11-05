module SearchHelper
  def filetype_icon(type, label, url)
    link_to(image_tag("filetypes/#{type}.png",
                      :alt => label,
                      :size => "24x24"),
            url)
  end
end
