module SearchHelper
  def drilldown_link(entry)
    case entry.key
    when :type
      filetype_icon(entry)
    else
      link_to_unless(@search_request.have_key?(entry.key),
                     entry.label, entry.path)
    end
  end

  def filetype_icon(entry)
    link_to_unless(@search_request.have_key?(entry.key),
                   image_tag("filetypes/#{entry.value}.png",
                             :alt => entry.label,
                             :size => "24x24"),
                   entry.path)
  end
end
