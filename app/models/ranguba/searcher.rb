class Ranguba::Searcher
  attr_accessor :query, :type, :category, :page

  def initialize(query: nil,
                 type: nil,
                 category: nil,
                 page: nil)
    @query = query
    @type = type
    @category = category
    @page = page
  end

  def search
    request = ::Ranguba::Entry.select
                .match_columns([
                                 "basename * 1000",
                                 "title * 100",
                                 "body",
                               ])
                .output_columns([
                                  "*",
                                  "_key",
                                  "_score",
                                ])
                .sort_keys(["-_score", "title"])
                .paginate(page)
    if query
      request = request
                  .query(query)
                  .query_flags([
                                 "ALLOW_COLUMN",
                                 "QUERY_NO_SYNTAX_ERROR",
                               ])
                  .columns("highlighted_title").stage("output")
                  .columns("highlighted_title").flags("COLUMN_SCALAR")
                  .columns("highlighted_title").type("ShortText")
                  .columns("highlighted_title").value("highlight_html(title)")
                  .columns("snippets").stage("output")
                  .columns("snippets").flags("COLUMN_VECTOR")
                  .columns("snippets").type("Text")
                  .columns("snippets").value("snippet_html(body)")
    end
    if type
      request = request.filter(:type, type)
    else
      request = request
                  .drilldowns("type").keys(["type"])
                  .drilldowns("type").sort_keys(["-_nsubrecs"])
                  .drilldowns("type").limit(-1)

    end
    if category
      request = request.filter(:category, category)
    else
      request = request
                  .drilldowns("category").keys(["category"])
                  .drilldowns("category").sort_keys(["-_nsubrecs"])
                  .drilldowns("category").limit(-1)

    end
    request.response
  end
end
