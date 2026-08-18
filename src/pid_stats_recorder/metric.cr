module PidStatsRecorder
  abstract class Metric
    abstract def key : String
    abstract def unit : String
    abstract def sample : Float64?

    def initialize(@pid : Int32)
    end

    def self.fetch(key, pid) : Metric
      case key
      when "rss"  then RssMetric.new(pid)
      when "swap" then SwapMetric.new(pid)
      when "cpu"  then CpuMetric.new(pid)
      when "threads" then ThreadsMetric.new(pid)
      else
        raise "Unknown metric: #{key}"
      end
    end

    def self.build(metrics : Array(String), pid : Int32) : Array(Metric)
      metrics.map { |k| fetch(k, pid) }
    end
  end

  module PidStatusUtils
    def extract_status_value(pid, ln_swith, default : String? = nil) : String?
      File.each_line("/proc/#{pid}/status") do |line|
        if line.starts_with?(ln_swith)
          return line.split(/\s+/)[1]
        end
      end

      default
    end
  end

  class RssMetric < Metric
    include PidStatusUtils

    def key : String
      "rss"
    end

    def unit : String
      "MB"
    end

    def sample : Float64?
      extract_status_value(@pid, "VmRSS:").try { |v| v.to_f / 1024.0 }
    end
  end

  class SwapMetric < Metric
    include PidStatusUtils

    def key : String
      "swap"
    end

    def unit : String
      "MB"
    end

    def sample : Float64?
      extract_status_value(@pid, "VmSwap:").try { |v| v.to_f / 1024.0 }
    end
  end

  class ThreadsMetric < Metric
    include PidStatusUtils

    def key : String
      "threads"
    end

    def unit : String
      "count"
    end

    def sample : Float64?
      extract_status_value(@pid, "Threads:").try &.to_f
    end
  end

  class CpuMetric < Metric
    CLK_TCK = 100

    @prev_ticks : {Int32, Int32}?
    @prev_sampled_at : Time::Instant?

    def key : String
      "cpu"
    end

    def unit : String
      "%"
    end

    def sample : Float64?
      ticks = cpu_ticks
      sampled_at = Time.instant

      percent = cpu_percent(ticks, sampled_at)

      @prev_ticks = ticks
      @prev_sampled_at = sampled_at

      percent
    end

    private def cpu_ticks : {Int32, Int32}
      stat = File.read("/proc/#{@pid}/stat")

      after_comm = stat[(stat.rindex(')').not_nil! + 2)..]
      fields = after_comm.split(/\s+/)

      utime = fields[11].to_i
      stime = fields[12].to_i

      {utime, stime}
    end

    private def cpu_percent(ticks : {Int32, Int32}, sampled_at : Time::Instant) : Float64?
      prev_ticks = @prev_ticks
      prev_sampled_at = @prev_sampled_at

      return nil unless prev_ticks && prev_sampled_at

      tick_delta = (ticks[0] + ticks[1]) - (prev_ticks[0] + prev_ticks[1])
      time_delta = (sampled_at - prev_sampled_at).total_seconds

      (tick_delta / CLK_TCK.to_f) / time_delta * 100
    end
  end
end
