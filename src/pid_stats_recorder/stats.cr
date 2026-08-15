module PidStatsRecorder
  class Stats
    getter samples : Array(Monitor::Stat)

    def initialize
      @samples = [] of Monitor::Stat
    end

    def record(stat : Monitor::Stat)
      @samples << stat
    end

    def rss_min : Int32
      @samples.map(&.rss_kb).min
    end

    def rss_max : Int32
      @samples.map(&.rss_kb).max
    end

    def rss_avg : Float64
      @samples.map(&.rss_kb).sum.to_f / @samples.size
    end

    def swap_min : Int32
      @samples.map(&.swap_kb).min
    end

    def swap_max : Int32
      @samples.map(&.swap_kb).max
    end

    def swap_avg : Float64
      @samples.map(&.swap_kb).sum.to_f / @samples.size
    end

    def cpu_min : Float64?
      cpu_samples.min?
    end

    def cpu_max : Float64?
      cpu_samples.max?
    end

    def cpu_avg : Float64?
      samples = cpu_samples
      return nil if samples.empty?

      samples.sum.to_f / samples.size
    end

    private def cpu_samples : Array(Float64)
      @samples.compact_map(&.cpu_percent)
    end
  end
end
