module Ranguba::SearchHelper
  def drilldown_link(entry)
    case entry.key
    when :type
      file_type_drilldown_link(entry)
    else
      topic_path = @topic_path.add(entry)
      link_to_unless(@search_request.have_key?(entry.key),
                     entry.label,
                     search_path(:search_request => topic_path.search_request))
    end
  end

  def file_type_drilldown_link(entry)
    topic_path = @topic_path.add(entry)
    relative_image_path = "file_types/#{entry.value}.png"
    full_image_path = Rails.root + "app/assets/images/#{relative_image_path}"
    if full_image_path.exist?
      content = image_tag("file_types/#{entry.value}.png",
                          :alt => entry.label,
                          :title => entry.label,
                          :size => "24x24")
    else
      content = entry.label
    end
    link_to_unless(@search_request.have_key?(entry.key),
                   content,
                   search_path(:search_request => topic_path.search_request))
  end

  def delete_topic_path_link(topic_path, item)
    topic_path = topic_path.delete_item(item)
    link_to(image_tag("delete.png",
                      :alt => item.reduce_title,
                      :size => "16x16"),
            search_path(:search_request => topic_path.search_request),
            :title => item.reduce_title,
            :class => "topic_path_reduce_link")
  end

  def drilldown_group_name(search_request, name)
    label = I18n.t("drilldown_group_label_#{name}")
    if search_request.empty?
      I18n.t("drilldown_group_label", :label => label)
    else
      I18n.t("drilldown_group_add_label", :label => label)
    end
  end

end
