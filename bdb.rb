#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/common'

require 'bdb'
require 'json'

# env = BDB::Env.open(File.dirname(__FILE__) + '/data',
#                     BDB::INIT_MPOOL | BDB::CREATE)

bdb = BDB::Btree.open("data/day.bdb",
                      nil,
                      BDB::CREATE | BDB::TRUNCATE,
                      "set_flags" => BDB::DUP)

cursor = bdb.cursor

Benchmark.bm do |x, logger|

  symbols = Set.new
  
  x.report("write:") do
    i = 0
    QuoteDay.each do |ohlc|
      break if i == MAX_RECORDS
      symbol = ohlc.delete("symbol")
      
      cursor.put(BDB::KEYFIRST, symbol, ohlc.to_json)
      
      i += 1
      symbols.add(symbol)
    end

    # bdb.sync
  end

  x.report("index:") do
    # no index needed
  end

  x.report("q30:") do
    symbols.each do |s|
      i = 0
      records = []
      bdb.each_dup(s, 30) do |key, value|
        records.push(JSON.parse(value))
        break if i += 1 and i == 30
      end
    end
  end

  x.report("qall:") do
    symbols.each do |s|
      records = bdb.duplicates(s, false).map do |value|
        JSON.parse(value)
      end
    end
  end

  logger << sprintf(",%d", bdb.size)
end

bdb.close
