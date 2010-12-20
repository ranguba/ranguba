require 'optparse/shellwords'
require 'shellwords'
require 'tmpdir'
require 'fileutils'
require 'time'
require 'chupatext'

class Ranguba::Indexer
  attr_accessor :wget, :log_file, :url_prefix, :level, :accept,
                :reject, :tmpdir, :auto_delete,
                :ignore_errors, :debug

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
    @auto_delete = true
    @ignore_errors = false
    @debug = false
    @oldest = nil

    encodings = Rails.configuration.ranguba_config_encodings
    @url_category_pair = Ranguba::CategoryLoader.new(encodings['categories.csv']).load
    @mime_type_pair = Ranguba::TypeLoader.new(encodings['types.csv']).load
    @authinfo_records = Ranguba::PasswordLoader.new.load

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
      @ignore_errors = v
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
      if args.empty? and (args = @url_category_pair.map(&:first)).empty?
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
        log(:info, " URL: #{url}")
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
        unless url and path and File.file?(path)
          log(:warn, "[file][not_found] path #{path}")
          next
        end
        add_entry(url, path, response)
        postprocess_file(path)
        path = nil
      end
    end
    result
  end

  def process_crawl(urls)
    url_auth_groups = {}

    @authinfo_records.each do |record|
      url_auth_groups[record[:url]] = {
        :authinfo => record,
        :urls => []
      }
    end

    no_auth_urls = []
    protected_urls = @authinfo_records.map{|record| record[:url]}

    urls.each do |target_url|
      protected_url = protected_urls.find{|protected_url|
        target_url.index(protected_url) == 0
      }
      if protected_url
        url_auth_groups[protected_url][:urls].push(target_url)
      else
        no_auth_urls.push(target_url)
      end
    end

    url_auth_groups.each do |_,group|
      unless group[:urls].empty?
        authinfo = group[:authinfo]
        process_crawl_urls(group[:urls],
                           :username => authinfo[:username],
                           :password => authinfo[:password])
      end
    end
    unless no_auth_urls.empty?
      process_crawl_urls(no_auth_urls)
    end
  end

  def process_crawl_urls(urls, options = {})
    base = Dir.mktmpdir("ranguba", @tmpdir)
    wget = [{"LC_ALL"=>"C"}, *@wget, "-r", "-l#{@level}", "-np", "-S"]
    wget << "--accept=#{@accept.join(',')}" unless @accept.empty?
    wget << "--reject=#{@reject.join(',')}" unless @reject.empty?
    wget << "--restrict-file-names=ascii"
    if options[:username] && options[:password]
      wget << "--http-user=#{options[:username]}"
      wget << "--http-password=#{options[:password]}"
    end
    wget.concat(urls)
    wget << {chdir: base, err: [:child, :out]}
    begin
      IO.popen(wget, "r", encoding: "utf-8") {|input|
        process_from_log(base, input)
      }
    ensure
      FileUtils.rm_rf(base) if @auto_delete
    end
    if @oldest
      purge_old_records(@oldest)
    end
  end

  def add_entry(url, path, response = {})
    begin
      metadata, body = decompose_file(path, response)
      if metadata.nil?
        log(:warn, "[decompose][failure] <#{url}>")
        return false
      end
      attributes = make_attributes(url, response, metadata, path)
      attributes.update(key: url, body: body, basename: url.split(/\//).last)
      return false unless valid_encoding?(attributes)
      ::Ranguba::Entry.create!(attributes)
    rescue => e
      unless @ignore_errors
        log(:error, "[error] #{e.class}: #{e.message}")
        log(:error, e.backtrace.map{|s|"\t#{s}"}.join("\n"))
        return false
      end
    end
    true
  end

  def postprocess_file(path)
    FileUtils.rm_f(path) if @auto_delete && @url_prefix.blank?
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
    rescue Chupa::Error => e
      log(:error, "[error] #{e.class}: #{e.message}")
      log(:error, "[error] path: #{path}")
      case e.code
      when Chupa::DecomposerErrorCode::ENCRYPTED
        return nil
      else
        raise
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
      type: normalize_type(meta.original_mime_type || ""),
      encoding: response["charset"] || meta.original_encoding || "",
      category: category_for_url(url) || "",
      author: meta.author || "",
      modified_at: modification_time,
      updated_at: response["x-update-time"],
    }
  end

  def category_for_url(url="")
    prefix, category = @url_category_pair.select do |prefix, category|
      url.start_with?(prefix)
    end.max_by do |prefix, category|
      prefix.length
    end
    category.blank? ? "unknown" : category
  end

  def normalize_type(source="")
    type = type_for_mime(source) || source.gsub(/^[^\/]+\/|\s*;\s*.*\z/, "").strip
    type.blank? ? "unknown" : type
  end

  def type_for_mime(source)
    source = source.sub(/\s*;\s*.*\z/, "").strip
    mime, type = @mime_type_pair.select{|mime, type|
      source == mime
    }.max_by{|mime, type|
      mime.length
    }
    type
  end

  private

  def valid_encoding?(attributes)
    url = attributes[:key]
    invalid_encoding_attributes = attributes.reject do |key, value|
      valid_utf8?(value)
    end
    invalid_encoding_keys = invalid_encoding_attributes.keys
    if invalid_encoding_keys.blank?
      true
    else
      log(:warn, "[encoding][invalid] key: #{url} - #{invalid_encoding_keys.join(',')}")
      false
    end
  end

  def valid_utf8?(value)
    return true unless value.respond_to?(:encode)
    value = value.dup
    value.force_encoding("UTF-8").valid_encoding?
  end

  def log(level, messeage)
    Rails.logger.send(level, "#{Time.now} [indexer]#{messeage}")
  end

end
