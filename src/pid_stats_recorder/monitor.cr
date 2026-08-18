module PidStatsRecorder
  class Monitor
    struct SampleResult
      getter recorded_at : Time
      getter samples : Hash(String, Float64?)
      getter units : Hash(String, String)

      def initialize(@recorded_at : Time, @samples : Hash(String, Float64?), @units : Hash(String, String))
      end

      def to_row(keys : Array(String)) : Array(String)
        [@recorded_at.to_s] + keys.map { |k| @samples[k].try { |v| v.round(2).to_s } || "" }
      end

      def to_s : String
        @samples.map { |key, value| "#{key}: #{value.try &.round(2)} #{units[key]?}" }.join("  ")
      end
    end

    getter metrics : Array(Metric)

    def initialize(@pid : Int32, metrics : Array(String))
      @metrics = Metric.build(metrics, pid)
    end

    def sample : SampleResult
      results = {} of String => Float64?
      units = {} of String => String

      @metrics.each do |metric|
        results[metric.key] = metric.sample
        units[metric.key] = metric.unit
      end

      SampleResult.new(Time.local, results, units)
    end
  end
end
