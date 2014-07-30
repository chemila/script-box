#!/bin/bash
#
# 安装：
# sudo ln -s $DIR_CUR/daemon-keeper.sh /bin/dk

#获得脚本的实际路径。（解决了软链问题）
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

#在终端显示彩色文本
function _cecho {
    case $2 in
        info )
            color=33;;
        error )
            color=31;;
        success )
            color=32;;
        *)
            color=1;;
    esac

    echo -e "\033["$color"m$1\033[0m"
}

#启动一个Job
function start {
    local cli=$@
    pid=`pgrep -f "$cli"`

    if [ -z "$pid" ]
    then
        nohup $cli &
    fi
}

#停止一个Job
function stop {
    local cli=$@
    pid=`pgrep -f "$cli"`

    if [ -n "$pid" ]
    then
        kill -9 $pid
    fi
}

#重启一个Job
function restart {
    local cli=$@
    stop $cli
    start $cli
}

function help {
    case $1 in
    "1")
        _cecho "你只能做以下操作：start | stop | restart" error;;
    "2")
        _cecho "必须提供job列表。" error;;
    "3")
        _cecho "-s 参数必填。可能值：start, stop, restart" error;;
    "4")
        _cecho "-f 参数必填。其值必须是一个可读的文件路径。" error;;
    "5")
        cd $(_current_path)
        echo -e "\033[1m"
        cat  HELP
        echo -e "\033[0m"
        ;;
    "6")
        _cecho "-t 必须是自然数" error;;
    "7")
        _cecho "只有设置了-d参数时，-t才有效。" error;;
    esac
    exit
}

#批量处理Job
function run {
    cat $2|while read job;do
        $1 $job
    done   
}

option_daemon=0
option_time=0

if [ $# -eq 0 ]
then
    help 5
fi

while getopts :s:f:vhdt: p
do
    case $p in
    s)
        if [ -z $OPTARG ]
        then
            help 1
        fi

        is_available=0
        for action in start stop restart
        do
            if [ $action = $OPTARG ]
            then
                is_available=1
                break
            fi
        done

        if [ $is_available == 0 ]
        then
            help 1
        fi

        option_act=$OPTARG;;
    f)
        if [ -z $OPTARG ]
        then
            help 2
        fi

        if [ -r $OPTARG ] && [ -f $OPTARG ]
        then
            _cecho 'running' info
        else
            help 2
        fi

        option_file=$OPTARG;;
    d)
        option_daemon=1;;
    t)
        if [ $OPTARG -gt 0 ] 2> /dev/null
        then
            option_time=$OPTARG
        else
            help 6
        fi;;
    v)
        _cecho "Deamon Keeper 1.0"
        exit 0;;
    h)
        help 5;;
    esac
done

if [ -z "$option_act" ]
then
    help 3
fi

if [ -z "$option_file" ]
then
    help 4
fi

if [ $option_time -gt 0 ] && [ $option_daemon -eq 0 ]
then
    help 7
fi

if [ $option_daemon -eq 1 ]
then
    if [ $option_act == "start" ] || [ $option_act == "stop" ]
    then
        while true
        do
            run $option_act $option_file

            if [ $option_time -gt 0 ]
            then
                echo "sleep $option_time"
                sleep $option_time
            fi
        done
    else
        echo "Restart can't be running as deamon."
        exit 0
    fi
else
    run $option_act $option_file
fi

# end of this file
