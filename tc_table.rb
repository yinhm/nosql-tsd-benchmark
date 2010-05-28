#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/common'

require 'tokyocabinet'
include TokyoCabinet

# create the object
tdb = TDB::new

# open the database
if !tdb.open("data/day.tct", TDB::OWRITER | TDB::OCREAT | TDB::OTRUNC)
  ecode = tdb.ecode
  STDERR.printf("open error: %s\n", tdb.errmsg(ecode))
end

Benchmark.bm do |x, logger|

  symbols = Set.new
  
  x.report("write:") do
    i = 0
    QuoteDay.each do |ohlc|
      break if i == MAX_RECORDS
      tdb.put("#{ohlc["symbol"]}:#{ohlc["date"]}", ohlc)
      i += 1
      symbols.add(ohlc["symbol"])
    end
  end

  x.report("index:") do
    tdb.setindex("symbol", TDB::ITLEXICAL)
    tdb.setindex("date", TDB::ITLEXICAL)
  end

  x.report("q30:") do
    symbols.each do |s|
      query = TDBQRY.new(tdb)
      query.addcond("symbol", TDBQRY::QCSTREQ, s)
      query.setlimit(30)
      query.setorder("date", TDBQRY::QOSTRDESC)
      records = query.search.collect do |pkey|
        tdb.get(pkey)
      end
    end
  end

  x.report("qall:") do
    symbols.each do |s|
      query = TDBQRY.new(tdb)
      query.addcond("symbol", TDBQRY::QCSTREQ, s)
      query.setorder("date", TDBQRY::QOSTRDESC)
      records = query.search.collect do |pkey|
        tdb.get(pkey)
      end
    end
  end

  logger << sprintf(",%d", tdb.fsiz)
end

tdb.close
