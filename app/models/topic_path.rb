require 'forwardable'

class TopicPath
  extend Forwardable
  include Enumerable

  def_delegators :@items, :first, :last, :empty?

  def initialize(*items)
    @items = items
  end

  def add(item)
    new_items = @items + [item]
    TopicPath.new(*new_items)
  end

  def delete_item(item)
    new_items = @items.dup
    new_items.delete(item)
    TopicPath.new(*new_items)
  end

  def delete_item_at(index)
    new_items = @items.dup
    new_items.delete_at(index)
    TopicPath.new(*new_items)
  end

  def [](*args)
    new_items = @items[*args]
    TopicPath.new(*new_items)
  end

  def title
    @items.map(&:label).join(I18n.t("search_conditions_delimiter"))
  end

  def search_request
    return nil if empty?
    @items.inject([]){|memo, item|
      if item.query_item?
        memo += [query_path] unless memo.any?{|v| /query/ =~ v }
      else
        memo += [item.path]
      end
      memo
    }.join('/')
  end

  def query_path
    first, *rest = @items.select{|item| item.query_item? }
    rest_terms = rest.map(&:value).join('+')
    rest_terms = "+#{rest_terms}" unless rest_terms.blank?
    "#{first.path}#{rest_terms}"
  end

  def each
    @items.each do |item|
      yield item
    end
  end

end
