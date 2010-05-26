#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/common'

require 'json'
require 'redis'

redis = Redis.new("localhost:6379:5")
redis.flushdb

Benchmark.bm do |x, logger|

  symbols = Set.new
  
  x.report("write:") do
    i = 0
    QuoteDay.each do |ohlc|
      break if i == MAX_RECORDS
      redis.lpush(ohlc["symbol"], ohlc.to_json)
      i += 1
      symbols.add(ohlc["symbol"])
    end
  end

  x.report("index:") do
    # no need
  end

  x.report("q30:") do
    symbols.each do |s|
      results = redis.lrange(s, 0, 29).map do |r|
        JSON.parse(r)
      end
    end
  end

  x.report("qall:") do
    symbols.each do |s|
      results = redis.lrange(s, 0, -1).map do |r|
        JSON.parse(r)
      end
    end
  end

  # db size: NO API
  # file size may not accurate due to other redis data exsits
  logger << sprintf(",%d", File.size("/var/lib/redis/dump.rdb"))
end
