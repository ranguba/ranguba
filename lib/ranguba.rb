# require 'groonga'

module Ranguba
  class Index
    def self.open(*args, &block)
      new.open(*args, &block)
    end

    def initialize
      @database = nil
    end

    def open(path, encoding = Encoding::UTF_8)
      if File.exist?(path)
        @database = Groonga::Database.open(path)
        populate_schema
      else
        FileUtils.mkdir_p(File.dirname(path))
        reset_context(encoding)
        populate(path)
      end
      if block_given?
        begin
          yield(self)
        ensure
          close unless closed?
        end
      end
    end

    def purge
      path = @database.path
      encoding = @database.encoding
      @database.remove
      FileUtils.rm_f([path, *Dir[path+".*"]])
      reset_context(encoding)
      populate(path)
    end

    def purge_old_records(base_time)
      old_entries = entries.select do |record|
        record.update < base_time
      end
      old_entries.each do |record|
        real_record = record.key
        real_record.delete
      end
    end

    def close
      @database.close
      @database = nil
    end

    def closed?
      @database.nil? or @database.closed?
    end

    def self.table_accessor(*names)
      names.each do |name|
        nv = name.gsub(/[a-z](?=[A-Z])/, '\&_').downcase
        iv = "@#{nv}"
        define_method(nv) do
          nv = instance_variable_get(iv)
          if not nv or nv.closed?
            nv = Groonga[name]
            instance_variable_set(iv, nv)
          end
          nv
        end
      end
    end

    table_accessor *%w[Types Charsets Categories Entries]

    def reset_context(encoding)
      Groonga::Context.default_options = {:encoding => encoding.to_s.downcase}
      Groonga::Context.default = nil
    end

    def populate(path)
      @database = Groonga::Database.create(:path => path)
      populate_schema
    end

    def populate_schema
      Groonga::Schema.define do |schema|
        schema.create_table("Types", :type => :hash,
                            :key_type => "ShortText") do |table|
        end

        schema.create_table("Charsets", :type => :hash,
                            :key_type => "ShortText") do |table|
        end

        schema.create_table("Categories", :type => :hash,
                            :key_type => "ShortText") do |table|
          table.text("title")
        end

        schema.create_table("Entries", :type => :hash,
                            :key_type => "ShortText") do |table|
          table.text("title")
          table.reference("type", "Types")
          table.reference("charset", "Charsets")
          table.reference("category", "Categories")
          table.short_text("author")
          table.time("mtime")
          table.time("update")
          table.text("body")
        end

        schema.create_table("Bigram",
                            :type => :patricia_trie,
                            :key_type => "ShortText",
                            :default_tokenizer => "TokenBigram",
                            :key_normalize => true) do |table|
          table.index("Entries.body", :with_position => true)
          table.index("Entries.title", :with_position => true)
        end

        schema.change_table("Types") do |table|
          table.index("Entries.type")
        end

        schema.change_table("Charsets") do |table|
          table.index("Entries.charset")
        end

        schema.change_table("Categories") do |table|
          table.index("Entries.category")
        end
      end
    end
  end
end

if $0 == __FILE__
  p Ranguba::Index.open(ARGV[0]).entries
end
