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
