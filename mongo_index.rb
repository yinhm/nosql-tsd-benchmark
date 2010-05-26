#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/common'

require 'mongo'

m = Mongo::Connection.new
m.drop_database('quotest2')
db = m.db("quotest2")

coll = db.collection("day")

Benchmark.bm do |x, logger|

  symbols = Set.new
  
  x.report("write:") do
    i = 0
    QuoteDay.each do |ohlc|
      break if i == MAX_RECORDS
      coll.insert(ohlc)
      i += 1
      symbols.add(ohlc["symbol"])
    end
  end

  x.report("index:") do
    coll.create_index([["symbol", Mongo::ASCENDING], ["date", Mongo::DESCENDING]])
  end

  x.report("q30:") do
    symbols.each do |s|
      results = coll.find("symbol" => s).sort(["date", "descending"]).limit(30).map do |r|
        r
      end
    end
  end

  x.report("qall:") do
    symbols.each do |s|
      results = coll.find("symbol" => s).sort(["date", "descending"]).map do |r|
        r
      end
    end
  end

  # db size: datasize + indexsize
  logger << sprintf(",%d", db.stats["dataSize"] + db.stats["indexSize"])
end
