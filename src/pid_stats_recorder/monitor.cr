module PidStatsRecorder
  class Monitor
    CLK_TCK = 100

    struct Stat
      getter recorded_at : Time
      getter rss_kb : Int32
      getter swap_kb : Int32
      getter cpu_percent : Float64?

      def initialize(@recorded_at : Time, @rss_kb : Int32, @swap_kb : Int32, @cpu_percent : Float64?)
      end
    end

    @prev_ticks : {Int32, Int32}?
    @prev_sampled_at : Time::Instant?

    def initialize(@pid : Int32)
    end

    def stats : Stat
      ticks = cpu_ticks
      sampled_at = Time.instant

      percent = cpu_percent(ticks, sampled_at)

      @prev_ticks = ticks
      @prev_sampled_at = sampled_at

      Stat.new(recorded_at: Time.local, rss_kb: rss_kb, swap_kb: swap_kb, cpu_percent: percent)
    end

    private def rss_kb : Int32
      File.each_line("/proc/#{@pid}/status") do |line|
        if line.starts_with?("VmRSS:")
          return line.split(/\s+/)[1].to_i
        end
      end

      raise "VmRSS not found for pid #{@pid}"
    end

    private def swap_kb : Int32
      File.each_line("/proc/#{@pid}/status") do |line|
        if line.starts_with?("VmSwap:")
          return line.split(/\s+/)[1].to_i
        end
      end

      raise "VmSwap not found for pid #{@pid}"
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
