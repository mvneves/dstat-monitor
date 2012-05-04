#!/bin/bash
# Script that uses dstat to aggretate relevant resource statistcs,
# write them to a CSV file and format this file to be directly imported 
# by R scripts.
#
# Marcelo Veiga Neves <marcelo.veiga@gmail.com>
#

if [ $# -lt 1 ]
then
	echo "Usage: $0 logfile [duration]"
	exit 1
fi

logfile=$1
if [ $# -eq 2 ]
then
	duration=$2
fi

dstat=/usr/bin/dstat

dstat_check()
{
	# Check if dstat is installed
	if [ ! -e "$dstat" ]
	then
		echo "Error: $dstat not found."
		exit 1
	fi

	# Check if the cpu temperature plugin is working
	$dstat --cputemp 1 0 >/dev/null 2>/dev/null
	if [ $? -ne 0 ]
	then
		echo "Error: cputemp plugin not working."
		exit 1
	fi
}

dstat_run()
{
	output=$1
	duration=$2

	# Build the CPU list as reported by dstat
	ncpu=`$dstat --cpu --full --nocolor 1 0 | head -n 1 | tr -d '-' | tr ' ' '\n' | wc -l`
	cpu_list="total"
	for i in `seq 1 $ncpu`
	do
		let i--
		cpu_list="$cpu_list,$i"
	done

	# Build the network interface list as reported by dstat
	ifaces=`$dstat --net --full --nocolor 1 0 | head -n 1 | tr -d '-' | sed 's/net\///g'`
	iface_list="total"
	for i in $ifaces
	do
		eth=`echo $i | sed -r 's/.*eth([0-9]*).*/\1/g'`
		iface_list="$iface_list,eth$eth"
	done

	# Build the IO devices list as reported by dstat
	disks=`$dstat --disk --full --nocolor --noupdate 1 0 | head -n 1 | sed 's/ /\n/g' | sed -r 's/.*dsk\/([^-]*).*/\1/g' | tr '\n' ' '`
	disk_list="total"
	for i in $disks
	do
		disk_list="$disk_list,$i"
	done

	rm -f $output
	cmd="$dstat --epoch --mem --swap --sys --page --cpu -C $cpu_list --net -N $iface_list --disk --io -D $disk_list --cpufreq --cputemp --nocolor --output $output 1 $duration"
	echo $cmd
	$cmd
}

dstat_parse()
{
	output=$1

	cpu_list=`cat $output | grep "Cmdline:" | sed -r 's/^.*--cpu -C ([^ ]+).*/\1/g'`
	disk_list=`cat $output | grep "Cmdline:" | sed -r 's/^.*--disk --io -D ([^ ]+).*/\1/g'`
	net_list=`cat $output | grep "Cmdline:" | sed -r 's/^.*--net -N ([^ ]+).*/\1/g'`

	m=`cat $output | sed '7!d' | tr ',' ' ' | tr -d '\"'`
	metrics=($m)

	n=0

	# timestamp
	line="timestamp"
	let n++

	# memory
	line="$line,mem_${metrics[n]}"
	let n++
	line="$line,mem_${metrics[n]}"
	let n++
	line="$line,mem_${metrics[n]}"
	let n++
	line="$line,mem_${metrics[n]}"
	let n++

	# swap
	line="$line,swap_${metrics[n]}"
	let n++
	line="$line,swap_${metrics[n]}"
	let n++

	# system
	line="$line,${metrics[n]}"
	let n++
	line="$line,${metrics[n]}"
	let n++

	# page
	line="$line,page_${metrics[n]}"
	let n++
	line="$line,page_${metrics[n]}"
	let n++

	# cpu
	for i in `echo $cpu_list | tr ',' ' '`
	do
		line="$line,cpu$i""_${metrics[n+0]}"
		line="$line,cpu$i""_${metrics[n+1]}"
		line="$line,cpu$i""_${metrics[n+2]}"
		line="$line,cpu$i""_${metrics[n+3]}"
		line="$line,cpu$i""_${metrics[n+4]}"
		line="$line,cpu$i""_${metrics[n+5]}"
		let n=n+6
	done

	# network
	for i in `echo $net_list | tr ',' ' '`
	do
	    line="$line,net_$i""_${metrics[n+0]}"
	    line="$line,net_$i""_${metrics[n+1]}"
	    let n=n+2
	done

	# disk
	for i in `echo $disk_list | tr ',' ' '`
	do
	    line="$line,disk_$i""_${metrics[n+0]}"
	    line="$line,disk_$i""_${metrics[n+1]}"
	    let n=n+2
	done

	# I/O
	for i in `echo $disk_list | tr ',' ' '`
	do
	    line="$line,io_$i""_${metrics[n+0]}"
	    line="$line,io_$i""_${metrics[n+1]}"
	    let n=n+2
	done

	# frequency
	for i in `echo $cpu_list | sed 's/total,//g' | tr ',' ' '`
	do
	    line="$line,freq_${metrics[n]}"
	    let n++
	done

	# temperature
	for i in `echo $cpu_list | tr ',' ' '`
	do
	    line="$line,temp_${metrics[n]}"
	    let n++
	done

	echo $line | tr ',' ';'
	cat $output | sed '1,7d' | sed -r 's/^([^\.]*)[^,]*(.*)/\1\2/g' | tr ',' ';'
}

dstat_check
dstat_run $logfile-dstat $duration
dstat_parse $logfile-dstat > $logfile

