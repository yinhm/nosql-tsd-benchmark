require 'rubygems'
require 'ccsv'
require 'set'
require 'benchmark'

MAX_RECORDS = 1000000

class QuoteDay
  def self.each(&block)
    Ccsv.foreach("data/source.csv") do |row|
      ohlc = {
        "symbol" => row[0],
        "date"   => row[1],
        "open"   => row[2],
        "high"   => row[3],
        "low"    => row[4],
        "close"  => row[5],
        "volume" => row[6],
        "amount" => row[7]
      }
      
      yield ohlc
    end
  end
end


module Benchmark
  def benchmark(caption = "", label_width = nil, fmtstr = nil, *labels) # :yield: report
    sync = STDOUT.sync
    STDOUT.sync = true
    label_width ||= 0
    fmtstr ||= FMTSTR
    raise ArgumentError, "no block" unless iterator?
    print caption

    logger = File.open("result/report.csv", "a+")
    logger << File.basename($0).split('.')[0]
    results = yield(Report.new(label_width, fmtstr, logger), logger)
    logger << "\n"
    
    STDOUT.sync = sync
    
    logger.close
  end

  module_function :benchmark

  class Report # :nodoc:
    def initialize(width = 0, fmtstr = nil, logger = nil)
      @width, @fmtstr, @logger = width, fmtstr, logger
    end

    #
    # Prints the _label_ and measured time for the block,
    # formatted by _fmt_. See Tms#format for the
    # formatting rules.
    #
    def item(label = "", *fmt, &blk) # :yield:
      print label.ljust(@width)
      res = Benchmark::measure(&blk)
      print res.format(@fmtstr, *fmt)
      @logger << sprintf(",%.2f", res.real.to_s)
      res
    end

    alias report item
  end
end
