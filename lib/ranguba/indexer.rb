require 'optparse/shellwords'
require 'shellwords'
require 'tmpdir'
require 'fileutils'
require 'time'
require 'chupa-text'

class Ranguba::Indexer
  attr_accessor :wget, :log_file, :url_prefix, :level, :accept,
                :reject, :tmpdir, :auto_delete, :safe_text_extracting,
                :ignore_errors, :debug

  module Loggable
    private
    def log(level, messeage)
      Rails.logger.send(level, "#{Time.now} [indexer]#{messeage}")
    end

    def flush_log
      Rails.logger.flush
    end
  end

  include Loggable

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
    @accept = %w[htm html doc docx xls xlsx ppt pptx pdf
                 odt fodt ods fods odp fodp txt
                 *.html* *.php* *.cgi*]
    @reject = []
    @exclude_directories = []
    @tmpdir = nil
    @auto_delete = true
    @safe_text_extracting = false
    @ignore_errors = false
    @debug = false
    @oldest = nil

    @resolver = Resolver.new
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
    parser.on("-X", "--exclude-directories=LIST", Array) do |v|
      @exclude_directories.concat(v)
    end
    parser.on("-d", "--tmpdir=TMPDIR") do |v|
      @tmpdir = v
    end
    parser.on("-D", "--[no-]auto-delete") do |v|
      @auto_delete = v
    end
    parser.on("--[no-]safe-text-extracting") do |v|
      @safe_text_extracting = v
    end
    parser.on("-i", "--[no-]ignore-errors") do |v|
      @ignore_errors = v
    end
    parser.on("--[no-]debug") do |v|
      @debug = v
    end
    parser.on("--no-buffer-log",
              "Don't buffer log.",
              "Log is buffered on production environment by default.",
              "Log isn't buffered on development environment by default.") do |buffer|
      Rails.logger.auto_flushing = !buffer
    end
    parser.on("--log-path=PATH",
              "Log to PATH.") do |path|
      original_logger = Rails.logger
      path = STDOUT if path == "-"
      logger = ActiveSupport::BufferedLogger.new(path)
      logger.level = original_logger.level
      logger.auto_flushing = original_logger.auto_flushing
      Rails.logger = logger
      original_logger.flush
    end
    parser.on("--[no-]redirect-stdout-to-log",
              "Redirect standard output to log.") do |boolean|
      if boolean
        STDOUT.reopen(Rails.logger.instance_variable_get("@log"))
      end
    end
    parser.on("--[no-]redirect-stderr-to-log",
              "Redirect standard error to log.") do |boolean|
      if boolean
        STDERR.reopen(Rails.logger.instance_variable_get("@log"))
      end
    end
    begin
      parser.parse!(argv)
    rescue OptionParser::ParseError => ex
      $stderr.puts ex.message
      exit 1
    end
  end

  def prepare(args)
    ChupaText::Decomposers.load
    @extractor = ChupaText::Extractor.new
    @extractor.apply_configuration(ChupaText::Configuration.default)
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
        log(:info, "[start][log]")
        if @log_file == '-'
          process_from_log(base, STDIN)
        else
          File.open(@log_file) {|input|
            process_from_log(base, input)
          }
        end
        log(:info, "[end][log]")
      }
    when @url_prefix
      # read local files
      return if args.empty?
      process = proc {
        log(:info, "[start][file]")
        process_files(args)
        log(:info, "[end][file]")
      }
    else
      # crawl
      if args.empty? and (args = @resolver.urls).empty?
        raise OptionParser::MissingArgument, "no URL"
        return
      end
      process = proc {
        log(:info, "[start][crawl]")
        process_crawl(args)
        log(:info, "[start][crawl]")
      }
    end

    lambda do
      log(:info, "[start]")
      process.call
      log(:info, "[end]")
    end
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
        url = $2.sub(/\A\(try:\s*\d+\)\s*/, '')
        log(:info, " URL: #{url}")
        if response = log[/^(?:  .*\n)+/]
          response = Hash[response.lines.grep(/^\s*([-A-Za-z0-9]+):\s*(.*)$/) {[$1.downcase, $2]}]
        end
        file = log[/^Saving to: [`'](.+)[`']$/, 1]
        next unless file      # failed to start download
        path = File.join(base, file.gsub(/\\'/, "'"))
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
    wget << "--max-redirect=0"
    wget << "--adjust-extension"
    wget << "--accept=#{@accept.join(',')}" unless @accept.empty?
    wget << "--reject=#{@reject.join(',')}" unless @reject.empty?
    wget << "--exclude-directories=#{@exclude_directories.join(',')}" unless @exclude_directories.empty?
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

  def add_entry(url, path, response={})
    begin
      unless need_update?(url, path, response)
        log(:info, "[skip] <#{url}>")
        entry = Ranguba::Entry.find(url)
        entry.category = @resolver.category_for_url(url) || "unknown"
        entry.save!
        return true
      end
      attributes = decompose_file(url, path, response)
      if attributes.nil?
        log(:warn, "[decompose][failure] <#{url}>")
        return false
      end
      Ranguba::Entry.create!(attributes)
    rescue => e
      unless @ignore_errors
        log(:error, "[error] #{e.class}: #{e.message}")
        log(:error, e.backtrace.map{|s|"\t#{s}"}.join("\n"))
        return false
      end
    end
    true
  end

  def need_update?(url, path, response)
    modification_time = response["last-modified"]
    return true if modification_time.nil?
    begin
      modification_time = Time.parse(modification_time)
    rescue
      modification_time = nil
    end
    modification_time ||= File.mtime(path) if path
    return true if modification_time.nil?

    entry = Ranguba::Entry.find(url)
    return true if entry.nil?
    entry_modification_time = entry.modified_at
    return true if entry_modification_time.nil?
    entry_modification_time < modification_time
  end

  def postprocess_file(path)
    FileUtils.rm_f(path) if @auto_delete && @url_prefix.blank?
  end

  def decompose_file(url, path, response={})
    if @safe_text_extracting
      decompose_file_in_sub_process(url, path, response)
    else
      decompose_file_in_same_process(url, path, response)
    end
  end

  def decompose_file_in_sub_process(url, path, response)
    result = IO.popen("-", "rb") do |io|
      if io
        io.read
      else
        result = decompose_file_in_same_process(url, path, response)
        Marshal.dump(result, STDOUT)
      end
    end
    status = $?
    if status.exited? && status.exitstatus.zero?
      Marshal.load(result)
    else
      log(:error, "[decompose][sub-process][error] #{result}")
      nil
    end
  end

  def decompose_file_in_same_process(url, path, response)
    data = nil
    begin
      input_data = ChupaText::InputData.new(path)
      @extractor.extract(input_data) do |extracted_data|
        data = extracted_data
      end
    rescue ChupaText::EncryptedError
      nil
    rescue ChupaText::Error => e
      log(:error, "[error] #{e.class}: #{e.message}")
      log(:error, "[error] path: #{path}")
    else
      return nil if data.nil?
      decomposed_file = DecomposedFile.new(@resolver, url, path, response,
                                           input_data, data)
      decomposed_file.attributes
    end
  end

  def purge_old_records(base_time)
    log(:info, "[purge][start] <#{base_time.iso8601}>")
    flush_log
    old_entries = ::Ranguba::Entry.select do |record|
      record.updated_at < base_time
    end
    old_entries.each(&:delete)
    log(:info, "[purge][end] <#{base_time.iso8601}>")
    flush_log
  end

  class Resolver
    def initialize
      encodings = Rails.configuration.ranguba_config_encodings
      @url_category_pair = Ranguba::CategoryLoader.new(encodings['categories.csv']).load
      @mime_type_pair = Ranguba::TypeLoader.new(encodings['types.csv']).load
    end

    def urls
      @url_category_pair.map(&:first)
    end

    def category_for_url(url)
      url ||= ''
      prefix, category = @url_category_pair.select do |prefix, category|
        url.start_with?(prefix)
      end.max_by do |prefix, category|
        prefix.length
      end
      category.blank? ? nil : category
    end

    def normalize_type(source)
      source ||= ''
      type = type_for_mime(source)
      type ||= source.gsub(/^[^\/]+\/|\s*;\s*.*\z/, "").strip
      type.blank? ? nil : type
    end

    def type_for_mime(source)
      source = source.sub(/\s*;\s*.*\z/, "").strip
      mime, type = @mime_type_pair.select do |mime, type|
        source == mime
      end.max_by do |mime, type|
        mime.length
      end
      type
    end
  end

  class DecomposedFile
    def initialize(resolver, url, path, response, input_data, data)
      @resolver = resolver
      @url = url
      @path = path
      @response = response
      @input_data = input_data
      @data = data
    end

    def attributes
      {
        key: @url,
        title: @data.attributes.title,
        body: @data.body,
        basename: @url.split(/\//).last,
        type: normalize_type(@input_data.mime_type),
        encoding: @response["charset"] || @input_data.attributes.encoding.to_s,
        category: category_for_url(@url) || "",
        author: @data.attributes.author || "",
        modified_at: modification_time,
        updated_at: @response["x-update-time"],
      }
    end

    private
    def modification_time
      modification_time = @response["last-modified"]
      modification_time ||= @data.attributes.modified_time
      if modification_time
        begin
          modification_time = Time.parse(modification_time)
        rescue
          modification_time = nil
        end
      end
      modification_time ||= File.mtime(@path) if @path
      modification_time
    end

    def category_for_url(url)
      @resolver.category_for_url(url) || "unknown"
    end

    def normalize_type(source)
      @resolver.normalize_type(source) || "unknown"
    end
  end
end
