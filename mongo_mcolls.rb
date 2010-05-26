#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/common'

require 'mongo'

m = Mongo::Connection.new
m.drop_database('quotest1')
db = m.db("quotest1")

Benchmark.bm do |x, logger|

  symbols = Set.new
  
  x.report("write:") do
    i = 0
    coll = nil
    QuoteDay.each do |ohlc|
      break if i == MAX_RECORDS
      symbol = ohlc.delete("symbol")
      s = symbols.add?(symbol)
      unless s.nil?
        coll = db.collection(symbol)
      end
      
      coll.insert(ohlc)
      i += 1
    end
  end

  x.report("index:") do
    # no index needed
  end

  x.report("q30:") do
    symbols.each do |s|
      coll = db.collection(s)
      results = coll.find().sort(["_id", "descending"]).limit(30).map do |r|
        r
      end
    end
  end

  x.report("qall:") do
    symbols.each do |s|
      coll = db.collection(s)
      results = coll.find().sort(["_id", "descending"]).map do |r|
        r
      end
    end
  end

  # db size: datasize + indexsize
  logger << sprintf(",%d", db.stats["dataSize"] + db.stats["indexSize"])
end
