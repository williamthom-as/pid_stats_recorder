require "csv"

module PidStatsRecorder
  class Export
    getter file_name : String

    @keys : Array(String)

    def initialize(@file_name : String, @metrics : Array(Metric))
      @keys = @metrics.map(&.key)
      @file = File.open(@file_name, "w")
      @csv = CSV::Builder.new(@file)
    end

    def write(sample : Monitor::SampleResult) : Nil
      @csv.row(sample.to_row(@keys))
      @file.flush
    end

    def write_header
      labels = @metrics.map { |metric| "#{metric.key} (#{metric.unit})" }
      @csv.row(["recorded_at"] + labels)
      @file.flush

      self
    end

    def close : Nil
      @file.close
    end
  end
end
