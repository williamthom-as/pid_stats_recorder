require "log"
require "option_parser"

require "./pid_stats_recorder/metric"
require "./pid_stats_recorder/monitor"
require "./pid_stats_recorder/stats"
require "./pid_stats_recorder/export"

module PidStatsRecorder
  VERSION = "0.1.0"

  Log.setup(:info, Log::IOBackend.new(STDOUT))

  pid : Int32? = nil
  frequency = 1
  file_name = nil
  metrics = ["rss", "swap", "cpu"]

  OptionParser.parse(gnu_optional_args: true) do |parser|
    parser.banner = "Usage: pid_stats_recorder --process PID [arguments]"
    parser.on("-p PID", "--process PID", "PID to monitor (required)") { |p| pid = p.to_i }
    parser.on("-f SECONDS", "--frequency SECONDS", "Sampling interval in seconds") { |f| frequency = f.to_i }
    parser.on("-m METRICS", "--metrics METRICS", "Metrics to monitor (comma separated list (ex: rss,swap,cpu))") { |m| metrics = m.split(",") }
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

  monitor = Monitor.new(local_pid, metrics)
  tracker = Stats.new

  exporter = if requested_file_name = file_name
               resolved_file_name = requested_file_name.empty? ? "#{Time.local.to_s("%Y%m%d_%H%M%S")}_#{local_pid}.csv" : requested_file_name

               Export.new(resolved_file_name, monitor.metrics)
                 .write_header
                 .tap { |export| Log.info { "Exporting to #{export.file_name}" } }
             end

  finish = -> do
    monitor.metrics.each do |metric|
      pre_label = "#{metric.key} (#{metric.unit}): "

      Log.info { pre_label + tracker.summarise(metric.key) }
    end

    if local_exporter = exporter
      local_exporter.close
      Log.info { "Exported to #{local_exporter.file_name}" }
    end

    exit
  end

  Signal::INT.trap { finish.call }

  loop do
    begin
      sample : Monitor::SampleResult = monitor.sample
      tracker.record(sample)
      exporter.try &.write(sample)

      Log.info { sample.to_s }

      sleep frequency.seconds
    rescue File::NotFoundError
      Log.error { "Process #{local_pid} no longer exists. Exiting..." }

      finish.call

      exit
    end
  end
end
