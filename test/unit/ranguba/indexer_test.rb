# -*- coding: utf-8 -*-
require 'test_helper'
require 'ranguba/indexer'

class Ranguba::IndexerTest < ActiveSupport::TestCase

  def setup
    @indexer = Ranguba::Indexer.new([])
  end

end
