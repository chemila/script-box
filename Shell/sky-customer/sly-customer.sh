#!/bin/bash

function _current_path {
    SOURCE=${BASH_SOURCE[0]}
    DIR=$( dirname "$SOURCE" )

    while [ -h "$SOURCE" ]
    do
        SOURCE=$(readlink "$SOURCE")
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
        DIR=$( cd -P "$( dirname "$SOURCE"  )" && pwd )
    done

    DIR=$( cd -P "$( dirname "$SOURCE" )" && pwd )
    echo $DIR
}

cur_dir=`_current_path`
cd $cur_dir

# get config
. cfg.sh

## options
while getopts :i:w: p
do
    case $p in
        i)
            if [ ! -z $OPTARG ];then
                max_interval=$OPTARG
            fi;;
        w)
            if [ ! -z $OPTARG ];then
                max_worker=$OPTARG
            fi;;
    esac
done

cur_max_worker=$max_worker

# run as a daemon
while true
do
    while [[ $worker_num -lt $cur_max_worker ]]
    do
        $job
        worker_num=$[ $worker_num + 1 ]
    done

    worker_num=0
    len=`$check_list_len`

    if [ $len -gt 0 ];then
        interval_num=0
        cur_max_worker=$len

        if [ $cur_max_worker -gt $max_worker ];then
            cur_max_worker=$max_worker
        fi
    else
        if [ $interval_num -lt $max_interval ];then
            interval_num=$[ $interval_num + 1 ]
        else
            interval_num=$max_interval
        fi
    fi

    echo queue length $len
    echo sleep seconds $interval_num
    echo worker amount $cur_max_worker
    echo "====================================================="

    sleep $interval_num
done
# end of this file