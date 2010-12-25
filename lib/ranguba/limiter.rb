require 'English'

class Ranguba::Limiter
  def initialize
    @types = {
      :cpu => :int,
      :rss => :size,
      :as => :size,
    }
  end

  def setup_default
    @types.each do |key, type|
      set_limit(key, type)
    end
  end

  private
  def set_limit(key, type)
    value = ENV["RANGUBA_LIMIT_#{key.to_s.upcase}"]
    return if value.nil?
    value = send("parse_#{type}", key, value)
    return if value.nil?
    rlimit_number = Process.const_get("RLIMIT_#{key.to_s.upcase}")
    soft_limit, hard_limit = Process.getrlimit(rlimit_number)
    if hard_limit < value
      log_hard_limit_over_value(key, value, hard_limit)
      return nil
    end
    limit_info = "soft-limit:#{soft_limit}, hard-limit:#{hard_limit}"
    log(:info, "[#{key}][set] <#{value}>(#{limit_info})")
    Process.setrlimit(rlimit_number, value, hard_limit)
  end

  def parse_int(key, value)
    begin
      Integer(value)
    rescue ArgumentError
      log_invalid_value(key, value, type, "int")
      nil
    end
  end

  def parse_size(key, value)
    return nil if value.nil?
    scale = 1
    case value
    when /GB?\z/i
      scale = 1024 ** 3
      number = $PREMATCH
    when /MB?\z/i
      scale = 1024 ** 2
      number = $PREMATCH
    when /KB?\z/i
      scale = 1024 ** 1
      number = $PREMATCH
    when /B?\z/i
      number = $PREMATCH
    else
      number = value
    end
    begin
      number = Float(number)
    rescue ArgumentError
      log_invalid_value(key, value, "size")
      return nil
    end
    (number * scale).to_i
  end

  def log_hard_limit_over_value(key, value, hard_limit)
    log(:warning, "[#{key}][large] <#{value}>(hard-limit:#{hard_limit})")
  end

  def log_invalid_value(key, value, type)
    log(:warning, "[#{key}][invalid] <#{value}>(#{type})")
  end

  def log(level, message)
    Rails.logger.send(level, "[limit]#{message}")
  end
end
