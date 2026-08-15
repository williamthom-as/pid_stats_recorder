##### pid_stats_recorder

Simple tool to stream the mem, swap and cpu usage of a process with optional
export to a csv file. Useful if you want to watermark process usage over 
time without sitting in htop watching.

Install

You must have installed Crystal 1.21.0, then run `shards build`. The binary 
will be at `./bin/pid_stats_recorder`.

Usage

Run `pid_stats_recorder --help` to see the flags. The only required flag is 
--process.

All options:

- `--process PID` required, pid to monitor
- `--frequency SECONDS` sampling interval, default 1
- `--export[=FILENAME]` write csv (add filename or use default)
- `--help` help
- `Ctrl+C` stop, prints RSS/swap/CPU min/avg/max calcs for monitored window

Examples
- `./bin/pid_stats_recorder --process 12345`
- `./bin/pid_stats_recorder --process 12345 --frequency 5`
- `./bin/pid_stats_recorder --process 12345 --export`
- `./bin/pid_stats_recorder --process 12345 --export=run1.csv`


```bash
> ./bin/pid_stats_recorder --process 42986 --frequency 15 -e 
2026-08-15T09:38:00.026823Z   INFO - Monitoring process 42986 every 15s (Ctrl+C to stop)
2026-08-15T09:38:00.026978Z   INFO - Exporting to pid_stats_recorder_42986_20260815_193800.csv
2026-08-15T09:38:00.027133Z   INFO - RSS: 177.6 MB  Swap: 0.0 MB  CPU: -
2026-08-15T09:38:21.270176Z   INFO - RSS: 177.8 MB  Swap: 0.0 MB  CPU: 1.3%
2026-08-15T09:38:36.271016Z   INFO - RSS: 215.2 MB  Swap: 0.0 MB  CPU: 2.5%
2026-08-15T09:38:51.271315Z   INFO - RSS: 180.5 MB  Swap: 0.0 MB  CPU: 4.2%
```