# -*- coding: utf-8 -*-
require 'test_helper'

class Ranguba::FileReaderTest < ActiveSupport::TestCase

  def test_read_csv
    path = Rails.root + 'tmp' + 'categories.csv'
    File.open(path, 'w+:sjis:utf-8') do |file|
      str=<<CSV
http://www.example.com/,public,オフィシャルサイト
http://www.example.com/test,test,テストサイト
CSV
      file.sync = true
      file.puts str
      assert_nothing_raised do
        Ranguba::FileReader.read_csv(file.path, Encoding.find('sjis')) do |row|
          # nop
        end
      end
    end
  ensure
    FileUtils.rm_f(path)
  end

end
