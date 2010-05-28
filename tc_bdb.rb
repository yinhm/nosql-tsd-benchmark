#!/usr/bin/env ruby

# using hidden features of the misc method
# http://tokyocabinetwiki.pbworks.com/37_hidden_features_of_the_misc_method?SearchFor=iternext&sp=1

require File.dirname(__FILE__) + '/common'

require 'tokyocabinet'
require 'json'
include TokyoCabinet

# create the object
bdb = ADB::new

# open the database
if !bdb.open("data/day.tcb#mode=wct")
  ecode = bdb.ecode
  STDERR.printf("open error: %s\n", bdb.errmsg(ecode))
end


Benchmark.bm do |x, logger|

  symbols = Set.new
  
  x.report("write:") do
    i = 0
    QuoteDay.each do |ohlc|
      break if i == MAX_RECORDS
      symbol = ohlc.delete("symbol")
      bdb.misc("putdupback", [symbol, ohlc.to_json])
      i += 1
      symbols.add(symbol)
    end

    bdb.sync
  end

  x.report("index:") do
    # no index needed
  end

  x.report("q30:") do

    symbols.each do |s|
      if !bdb.misc("iterinit", [s])
        ecode = bdb.ecode
        STDERR.printf("put error: %s\n", bdb.errmsg(ecode))
      end
      
      i = 0
      records = []
      key, value = bdb.misc("iternext")
      while key == s
        records.push(JSON.parse(value))
        break if (i += 1) && i == 30
        key, value = bdb.misc("iternext")
      end
    end
  end

  x.report("qall:") do
    symbols.each do |s|
      if !bdb.misc("iterinit", [s])
        ecode = bdb.ecode
        STDERR.printf("put error: %s\n", bdb.errmsg(ecode))
      end

      records = []
      key, value = bdb.misc("iternext")
      while key == s
        records.push(JSON.parse(value))
        key, value = bdb.misc("iternext")
      end
    end
  end

  logger << sprintf(",%d", bdb.size)
end

bdb.close
