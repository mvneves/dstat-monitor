# dstat-monitor

Script that uses dstat to aggretate relevant resource statistcs, write them 
to a CSV file and format this file to be directly imported by R scripts.

## Usage

	Usage: dmon [options] command [logfile [duration]]

	Commands:
	dmon start logfile [duration]   Start monitor
	dmon status                         Verify monitor status
	dmon stop                           Stop monitor
	dmon parse logfile              Convert log file to a R-friendly format
	
	Options:
	 -i, --interval INTERVAL Specify monitoring interval in seconds (default: 1)
	 -v, --verbose           Make the operation more talkative
	 -h, --help              Print this help message
	
## Example


Start monitor:

	dmon start output.txt

Stop monitor:

	dmon stop

Parse output file:

	dmon parse output.txt

