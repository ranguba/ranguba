require 'optparse/shellwords'
require 'shellwords'
require 'tmpdir'
require 'fileutils'
require 'time'
require 'chupatext'
require 'ranguba/database'

class Ranguba::Indexer
  def initialize
    @wget = %w[wget]
    @log_file = nil
    @url_prefix = nil
    @level = 5
    @accept = %w[html doc xls ppt pdf]
    @reject = []
    @category_file = nil
    @category_table = {}
    @tmpdir = nil
    @auto_delete = false
    @ignore_erros = false
    @debug = false
    @oldest = nil
  end

  def set_options(opts)
    banner = opts.banner
    opts.banner = <<EOS
#{banner} db-path [URL...]
#{banner} --from-log=LOG db-path base-directory
#{banner} --url-prefix=PREFIX db-path files...

EOS

    opts.define("-w", "--wget[=WGET-PATH]", Shellwords) do |v|
      @wget = v
    end
    opts.define("-f", "--from-log=FILE") do |v|
      @log_file = v
    end
    opts.define("-p", "--url-prefix=URL_PREFIX") do |v|
      @url_prefix = v
    end
    opts.define("-l", "--level=NUMBER", Integer) do |v|
      @level = v
    end
    opts.define("-A", "--accept=LIST", Array) do |v|
      @accept.concat(v)
    end
    opts.define("-R", "--reject=LIST", Array) do |v|
      @reject.concat(v)
    end
    opts.define("-c", "--category-file=CATEGORY_FILE") do |v|
      @category_file = v
    end
    opts.define("-d", "--tmpdir=TMPDIR") do |v|
      @tmpdir = v
    end
    opts.define("-d", "--[no-]auto-delete") do |v|
      @auto_delete = v
    end
    opts.define("-i", "--[no-]ignore-errors") do |v|
      @ignore_erros = v
    end
    opts.define("--[no-]debug") do |v|
      @debug = v
    end
    opts
  end

  def prepare(args)
    db = args.shift
    return if db.nil?
    if @log_file
      if @url_prefix
        raise OptionParser::InvalidOption, "--url-prefix and --from-log options are exclusive"
      end
    end
    case
    when @log_file
      # load log file and read local downloads
      base = args.shift
      return if base.nil?
      return unless args.empty?
      Dir.open(base) {}
      process = proc {
        if @log_file == '-'
          process_from_log(db, base, STDIN)
        else
          File.open(@log_file) {|input|
            process_from_log(db, base, input)
          }
        end
      }
    when @url_prefix
      # read local files
      return if args.empty?
      process = proc {
        process_files(db, args)
      }
    else
      # crawl
    end

    if @category_file
      File.foreach(@category_file) do |line|
        next if /^\s*(?#|$)/ =~ line
        cat, title = line.strip.split(/\t+/)
        @category_table[cat] ||= title
      end
    end

    unless process
      if args.empty? and (args = @category_table.keys).empty?
        raise OptionParser::MissingArgument, "no URL"
        return
      end
      process = proc {
        @auto_delete = true
        base = Dir.mktmpdir("ranguba", @tmpdir)
        wget = [{"LC_ALL"=>"C"}, *@wget, "-r", "-l#{@level}", "-np", "-S"]
        wget << "--accept=#{@accept.join(',')}" unless @accept.empty?
        wget << "--reject=#{@reject.join(',')}" unless @reject.empty?
        wget.concat(args)
        wget << {chdir: base, err: [:child, :out]}
        begin
          IO.popen(wget, "r", encoding: "us-ascii") {|input|
            process_from_log(db, base, input)
          }
        ensure
          FileUtils.rm_rf(base)
        end
        if @oldest
          purge_old_records(@oldest)
        end
      }
    end

    process
  end

  def process_files(db, paths)
    require 'find'
    Find.find(*paths) do |path|
      next unless File.file?(path)
      puts "File: #{path}"
      process_file(db, path)
    end
    true
  end

  def process_file(db, path)
    result = false
    Ranguba::Database.open(db) do |grn|
      url = @url_prefix ? @url_prefix + path : path
      result = add_entry(grn, url, path)
      postprocess_file(path)
    end
    result
  end

  def process_from_log(db, base, input)
    result = true
    Ranguba::Database.open(db) do |grn|
      url = response = file = path = nil
      input.each("") do |log|
        case log
        when /^--([-\d]+.*?)\s*--\s+(.+)/
          update = $1
          url = $2
          puts "URL: #{url}"
          if response = log[/^(?:  .*\n)+/]
            response = Hash[response.lines.grep(/^\s*([-A-Za-z0-9]+):\s*(.*)$/) {[$1.downcase, $2]}]
          end
          file = log[/^Saving to: \`(.+)\'$/, 1]
          next unless file      # failed to start download
          path = File.join(base, file)
          response ||= {}
          update = Time.parse(update)
          response["x-update-time"] = update
          if !@oldest or @oldest > update
            @oldest = update
          end
        when /saved/
          next unless url and path and File.file?(path)
          add_entry(grn, url, path, response)
          postprocess_file(path)
          path = nil
        end
      end
    end
    result
  end

  def add_entry(grn, url, path, response = {})
    begin
      metadata, body = decompose_file(path, response)
      return false if metadata.nil?
      attributes = make_attributes(url, response, metadata, path)
      attributes.update(body: body)
      grn.entries.add(url, attributes)
    rescue => e
      unless @ignore_erros
        STDERR.puts "#{e.class}: #{e.message}"
        STDERR.puts e.backtrace.map{|s|"\t#{s}"}
        return false
      end
    end
    true
  end

  def postprocess_file(path)
    if @auto_delete
      FileUtils.rm_f(path)
    end
  end

  def decompose_file(path, response = {})
    begin
      data = Chupa::Data.decompose(path)
    rescue GLib::Error => e
      if @debug
        raise unless /unknown mime-type/ =~ e.message
      end
    else
      if data
        meta = data.metadata
        body = data.read || ""
        if body.encoding == Encoding::ASCII_8BIT
          body.force_encoding(meta["encoding"] || Encoding::UTF_8)
          return unless body.valid_encoding?
        end
        return meta, body
      end
    end
  end

  def make_attributes(url, response, meta, path)
    if mtime = response["last-modified"] || meta["last-modified"]
      begin
        mtime = Time.parse(mtime)
      rescue
        mtime = nil
      end
    end
    mtime ||= File.mtime(path) if path
    {
      title: meta["title"],
      type: mime_type_to_filetype(response["content-type"] || meta["mime-type"] || ""),
      charset: response["charset"] || meta["charset"] || "",
      category: get_category(url) || "",
      author: get_author(meta) || "",
      mtime: mtime,
      update: response["x-update-time"],
    }
  end

  private

  def get_category(url)
    cat, title = @category_table.select {|c, t| url.start_with?(c)}.max_by {|c, t| c.length}
    title
  end

  def get_author(meta)
    meta["author"]
  end

  def mime_type_to_filetype(mime_type)
    filetype = mime_type.sub(/^[^\/]+\//, "")
    filetype.blank? ? "unknown" : filetype
  end
end

class Ranguba::Indexer::TestOnly < Ranguba::Indexer
  SUFFIX_TYPE = {'.html' => 'text/html', '.txt' => 'text/plain'}

  def decompose_file(path, response = {})
    case response["content-type"] ||= SUFFIX_TYPE[File.extname(path)]
    when "text/html"
      return decompose_html_file(path, response)
    when "text/plain"
      return decompose_text_file(path, response)
    else
      super
    end
  end

  def decompose_text_file(path, response)
    File.open(path) {|f|
      meta = response.update("last-modified" => f.mtime,
                             "mime-type" => response["content-type"])
      return meta, f.read
    }
  end

  def decompose_html_file(path, response)
    require 'nokogiri'
    doc = File.open(path, 'rb') {|file| Nokogiri::HTML.parse(file)}
    metadata = {}
    if title = (doc % "head/title")
      metadata["title"] = title.text
    end
    if encoding = doc.encoding
      metadata["charset"] = encoding.downcase
    end
    if body = (doc % "body")
      body = body.text.gsub(/^\s+|\s+$/, '')
    end
    return metadata, body
  end
end

