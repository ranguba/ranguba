module SearchHelper
  def drilldown_link(entry)
    case entry.key
    when :type
      file_type_drilldown_link(entry)
    else
      link_to_unless(@search_request.have_key?(entry.key),
                     entry.label, entry.path)
    end
  end

  def file_type_drilldown_link(entry)
    link_to_unless(@search_request.have_key?(entry.key),
                   image_tag("file_types/#{entry.value}.png",
                             :alt => entry.label,
                             :size => "24x24"),
                   entry.path)
  end
end
