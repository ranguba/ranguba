require 'optparse/shellwords'
require 'shellwords'
require 'tmpdir'
require 'fileutils'
require 'time'
require 'chupatext'

class Ranguba::Indexer
  attr_accessor :wget, :log_file, :url_prefix, :level, :accept,
                :reject, :tmpdir, :auto_delete,
                :ignore_erros, :debug

  def accept=(val)
    @accept.concat(val)
    val
  end

  def reject=(val)
    @reject.concat(val)
    val
  end

  def initialize(argv)
    @wget = %w[wget]
    @log_file = nil
    @url_prefix = nil
    @level = 5
    @accept = %w[html doc xls ppt pdf]
    @reject = []
    @tmpdir = nil
    @auto_delete = false
    @ignore_erros = false
    @debug = false
    @oldest = nil

    parser = OptionParser.new
    banner = parser.banner
    parser.banner = <<EOS
#{banner} [URL...]
#{banner} --from-log=LOG base-directory
#{banner} --url-prefix=PREFIX files...

EOS

    parser.on("-w", "--wget[=WGET-PATH]", Shellwords) do |v|
      @wget = v
    end
    parser.on("-f", "--from-log=FILE") do |v|
      @log_file = v
    end
    parser.on("-p", "--url-prefix=URL_PREFIX") do |v|
      @url_prefix = v
    end
    parser.on("-l", "--level=NUMBER", Integer) do |v|
      @level = v
    end
    parser.on("-A", "--accept=LIST", Array) do |v|
      @accept.concat(v)
    end
    parser.on("-R", "--reject=LIST", Array) do |v|
      @reject.concat(v)
    end
    parser.on("-d", "--tmpdir=TMPDIR") do |v|
      @tmpdir = v
    end
    parser.on("-D", "--[no-]auto-delete") do |v|
      @auto_delete = v
    end
    parser.on("-i", "--[no-]ignore-errors") do |v|
      @ignore_erros = v
    end
    parser.on("--[no-]debug") do |v|
      @debug = v
    end
    begin
      parser.parse!(argv)
    rescue OptionParser::ParseError => ex
      $stderr.puts ex.message
      exit 1
    end
  end

  def prepare(args)
    if @log_file and @url_prefix
      raise OptionParser::InvalidOption, "--url-prefix and --from-log options are exclusive"
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
          process_from_log(base, STDIN)
        else
          File.open(@log_file) {|input|
            process_from_log(base, input)
          }
        end
      }
    when @url_prefix
      # read local files
      return if args.empty?
      process = proc {
        process_files(args)
      }
    else
      # crawl
      if args.empty? and (args = Ranguba::Customize.category_definitions.keys).empty?
        raise OptionParser::MissingArgument, "no URL"
        return
      end
      process = proc {
        process_crawl(args)
      }
    end

    process
  end

  def process_files(paths)
    require 'find'
    Find.find(*paths) do |path|
      next unless File.file?(path)
      puts "File: #{path}"
      process_file(path)
    end
    true
  end

  def process_file(path)
    url = @url_prefix ? @url_prefix + path : path
    result = add_entry(url, path)
    postprocess_file(path)
    result
  end

  def process_from_log(base, input)
    result = true
    url = response = file = path = nil
    input.each("") do |log|
      next unless log.valid_encoding?
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
        add_entry(url, path, response)
        postprocess_file(path)
        path = nil
      end
    end
    result
  end

  def process_crawl(args)
    @auto_delete = true
    base = Dir.mktmpdir("ranguba", @tmpdir)
    wget = [{"LC_ALL"=>"C"}, *@wget, "-r", "-l#{@level}", "-np", "-S"]
    wget << "--accept=#{@accept.join(',')}" unless @accept.empty?
    wget << "--reject=#{@reject.join(',')}" unless @reject.empty?
    wget.concat(args)
    wget << {chdir: base, err: [:child, :out]}
    begin
      IO.popen(wget, "r", encoding: "utf-8") {|input|
        process_from_log(base, input)
      }
    ensure
      FileUtils.rm_rf(base)
    end
    if @oldest
      purge_old_records(@oldest)
    end
  end

  def add_entry(url, path, response = {})
    begin
      metadata, body = decompose_file(path, response)
      return false if metadata.nil?
      attributes = make_attributes(url, response, metadata, path)
      attributes.update(key: url, body: body)
      ::Ranguba::Entry.create!(attributes)
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
      input_data = Chupa::Data.new(path)
      data = nil
      feeder = Chupa::Feeder.new
      feeder.signal_connect("accepted") do |_feeder, _data|
        data = _data
      end
      feeder.feed(input_data)
    rescue GLib::Error => e
      if @debug
        raise unless /unknown mime-type/ =~ e.message
      end
    else
      if data
        meta = data.metadata
        body = data.read || ""
        if body.encoding == Encoding::ASCII_8BIT
          body.force_encoding(meta.encoding || Encoding::UTF_8)
          return unless body.valid_encoding?
        end
        return meta, body
      end
    end
  end

  def purge_old_records(base_time)
    old_entries = ::Ranguba::Entry.select do |record|
      record.updated_at < base_time
    end
    old_entries.each(&:delete)
  end

  def make_attributes(url, response, meta, path)
    modification_time = response["last-modified"] || meta.modification_time
    if modification_time
      begin
        modification_time = Time.parse(modification_time)
      rescue
        modification_time = nil
      end
    end
    mtime ||= File.mtime(path) if path
    {
      title: meta.title,
      type: Ranguba::Customize.normalize_type(meta.original_mime_type || ""),
      encoding: response["charset"] || meta.original_encoding || "",
      category: Ranguba::Customize.category_for_url(url) || "",
      author: meta.author || "",
      modified_at: modification_time,
      updated_at: response["x-update-time"],
    }
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

