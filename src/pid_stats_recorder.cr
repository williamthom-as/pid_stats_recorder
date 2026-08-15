require "log"
require "option_parser"

require "./pid_stats_recorder/monitor"
require "./pid_stats_recorder/stats"
require "./pid_stats_recorder/export"

module PidStatsRecorder
  VERSION = "0.1.0"

  Log.setup(:info, Log::IOBackend.new(STDOUT))

  pid : Int32? = nil
  frequency = 1
  file_name = nil

  OptionParser.parse(gnu_optional_args: true) do |parser|
    parser.banner = "Usage: pid_stats_recorder --process PID [arguments]"
    parser.on("-p PID", "--process PID", "PID to monitor (required)") { |p| pid = p.to_i }
    parser.on("-f SECONDS", "--frequency SECONDS", "Sampling interval in seconds") { |f| frequency = f.to_i }
    parser.on("-e [FILENAME]", "--export [FILENAME]", "Export to file as CSV (file name not required)") { |f| file_name = f }
    parser.on("-h", "--help", "Show help") { puts parser; exit }
  end

  local_pid = pid
  unless local_pid
    STDERR.puts "Error: --process PID is required"
    exit 1
  end

  unless Process.exists?(local_pid)
    STDERR.puts "Error: no process with PID #{local_pid}"
    exit 1
  end

  Log.info { "Monitoring process #{local_pid} every #{frequency}s (Ctrl+C to stop)" }

  monitor = Monitor.new(local_pid)
  tracker = Stats.new

  exporter = if requested_file_name = file_name
    resolved_file_name = requested_file_name.empty? ? "pid_stats_recorder_#{local_pid}_#{Time.local.to_s("%Y%m%d_%H%M%S")}.csv" : requested_file_name
    Export.new(resolved_file_name).tap { |export| Log.info { "Exporting to #{export.file_name}" } }
  end

  Signal::INT.trap do
    rss_min = (tracker.rss_min / 1024.0).round(1)
    rss_avg = (tracker.rss_avg / 1024.0).round(1)
    rss_max = (tracker.rss_max / 1024.0).round(1)

    Log.info {
      "RSS  min/avg/max (MB): #{rss_min}/#{rss_avg}/#{rss_max}"
    }

    swap_min = (tracker.swap_min / 1024.0).round(1)
    swap_avg = (tracker.swap_avg / 1024.0).round(1)
    swap_max = (tracker.swap_max / 1024.0).round(1)

    Log.info { "Swap min/avg/max (MB): #{swap_min}/#{swap_avg}/#{swap_max}" }

    cpu_min = tracker.cpu_min.try &.round(1)
    cpu_avg = tracker.cpu_avg.try &.round(1)
    cpu_max = tracker.cpu_max.try &.round(1)

    Log.info { "CPU  min/avg/max (%): #{cpu_min}/#{cpu_avg}/#{cpu_max}" }

    if local_exporter = exporter
      local_exporter.close
      Log.info { "Exported to #{local_exporter.file_name}" }
    end

    exit
  end

  loop do
    sample = monitor.stats
    tracker.record(sample)
    exporter.try &.write(sample)
    Log.info { "RSS: #{(sample.rss_kb / 1024.0).round(1)} MB  Swap: #{(sample.swap_kb / 1024.0).round(1)} MB  CPU: #{sample.cpu_percent.try &.round(1)}%" }

    sleep frequency.seconds
  end
end
