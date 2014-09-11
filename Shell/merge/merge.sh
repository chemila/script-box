#!/bin/bash
#
# Merge develop to master for one repository.
# Demo:
#     merge.sh "app-render app-hf-xf" log
#     merge.sh "app-render app-hf-xf" cmd

# Get this script real path.
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

# Colorful printing.
# Demo:
#     _cecho 'hello' error
function _cecho {
    if [ "$is_cmd" = "log" ];then
        echo $1
        return
    fi

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

# Echo and run.
function _ear {
    _cecho "$@" success
    $@
}

# Merge develop to master.
# @param string the path of repository.
# @param string the path of git.
# Demo:
#     _merge /home/www/code/hf-index/ /bin/git
function _merge {
    cd $1
    _ear "$2 clean -df"
    _ear "$2 reset --hard"
    _ear "$2 checkout master"
    _ear "$2 pull origin master"
    _ear "$2 checkout $3"
    _ear "$2 pull origin $3"
    _ear "$2 checkout master"

    msg="merge $3"
    _cecho "$2 merge $3 --no-ff -m '$msg'" success
    $2 merge $3 --no-ff -m "'$msg'"

    result=$?

    if [ $result -eq 0 ];then
        _ear "$2 push origin master"
    else
        _cecho "Merging failed" error
        _unlock
        exit $errcode_merge_failed
    fi
}

# Add lock.
function _lock {
    echo 1 > $lock_file
}

# Clear lock.
function _unlock {
    rm -f $lock_file
}

# Check lock.
function _check_lock {
    if [ -f "$lock_file" ];then
        _cecho 'Now locking!' error
        exit $errcode_locked
    fi
}

errcode_need_repo=1
errcode_no_such_folder=2
errcode_locked=3
errcode_merge_failed=4
errcode_branch_needed=5

current_path=$(_current_path)
. $current_path/config.sh

_check_lock

if [ ! "$1" ];then
    _cecho 'Repository name is needed.' error
    exit $errcode_need_repo
fi

if [ ! "$2" ];then
    _cecho 'Which branch would you like to merge?' error
    exit $errcode_branch_needed
fi

branchname=$2

if [ ! $3 ];then
    is_cmd="cmd"
else
    is_cmd=$3
fi

_lock
repos=$1

for repo in $repos
do
    repo_path=$code_path$repo

    if [ ! -d $repo_path ];then
        _cecho "No such folder : $repo_path" error
        _unlock
        exit $errcode_no_such_folder
    fi

    _cecho "Handle Repository: $repo"
    _merge $repo_path $git $branchname
    hr
done

_unlock

_cecho "Finished!"

# end of this file
