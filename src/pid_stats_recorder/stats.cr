module PidStatsRecorder
  class Stats
    getter samples : Hash(String, Array(Float64))

    def initialize
      @samples = Hash(String, Array(Float64)).new { |h, k| h[k] = [] of Float64 }
    end

    def record(sample : Monitor::SampleResult) : Nil
      sample.samples.each do |key, value|
        @samples[key] << value if value
      end
    end

    def summarise(key : String) : String
      content = "#{min(key)}/#{avg(key)}/#{max(key)} (min/avg/max)"
    end

    def min(key : String) : Float64?
      @samples[key]?.try(&.min?).try(&.round(2))
    end

    def max(key : String) : Float64?
      @samples[key]?.try(&.max?).try(&.round(2))
    end

    def avg(key : String) : Float64?
      values = @samples[key]?

      return nil if !values || values.empty?

      (values.sum / values.size).round(2)
    end
  end
end
