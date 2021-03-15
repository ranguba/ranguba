# -*- coding: utf-8 -*-
require 'test_helper'

class Ranguba::FileReaderTest < ActiveSupport::TestCase

  def test_read_csv
    FileUtils.mkdir_p(Rails.root + 'tmp')
    path = Rails.root + 'tmp' + 'categories.csv'
    File.open(path, 'w+:sjis:utf-8') do |file|
      str=<<CSV
http://www.example.com/,public,オフィシャルサイト
http://www.example.com/test,test,テストサイト
CSV
      file.sync = true
      file.puts str
      Ranguba::FileReader.read_csv(file.path, Encoding::Shift_JIS) do |row|
        assert_equal([Encoding::UTF_8, Encoding::UTF_8, Encoding::UTF_8],
                     row.collect(&:encoding), row.first)
      end
    end
  ensure
    FileUtils.rm_f(path)
  end

end
