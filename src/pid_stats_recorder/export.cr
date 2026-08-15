require "csv"

module PidStatsRecorder
  class Export
    getter file_name : String

    def initialize(@file_name : String)
      @file = File.open(@file_name, "w")
      @csv = CSV::Builder.new(@file)
      @csv.row "recorded_at", "rss_kb", "swap_kb", "cpu_percent"
      @file.flush
    end

    def write(sample : Monitor::Stat) : Nil
      @csv.row sample.recorded_at, sample.rss_kb, sample.swap_kb, sample.cpu_percent
      @file.flush
    end

    def close : Nil
      @file.close
    end
  end
end
