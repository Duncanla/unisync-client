# -* bash -*

#
# Unisync client
# 
# Copyright (c) 2012, Luke Duncan <Duncan72187@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public license version 2 as
# published by the Free Software Foundation. See COPYING for more details.
#

set -e
set -u

etc_dir=@pkgsysconfdir@

unisync_conf=$etc_dir/unisync-client.conf
source $unisync_conf

targets_dir=$UNISYNC_DIR/targets
connection_dir=$UNISYNC_DIR/connections

pid_file=$UNISYNC_DIR/unisync-client.pid

connect_cmd_name=`echo unisync-client-connect | sed '@program_transform_name@'`

user_conf_file=$UNISYNC_DIR/unisync-client.lua
blank_user_conf=$etc_dir/unisync-client-userconf.lua

function usage {
    cat << EOF
Usage:
% unisync-client [OPTION]

Options: 
    --help      Print this message
    --version   Print version information

Submit bug reports at github.com/Duncanla/unisync-client
EOF
}

function version {
    cat <<EOF
unisync-client @VERSION@
Unisync client for syncing directories with a host

This is free software, and you are welcome to redistribute it and modify it 
under certain conditions. There is ABSOLUTELY NO WARRANTY for this software.
For legal details see the GNU General Public License.

EOF
}

# Parse options
if test $# -ne 0
then
  case $1 in
  --help)
    usage
    exit
    ;;
  --version)
    version
    exit
    ;;
  *)
    usage
    exit
    ;;
fi

# Cleanup for trapped signals
function cleanup {
    rm -rf $targets_dir/*
    rm -f $pid_file

    kill_open_connections

    err_msg "Client died!"

    trap - EXIT
    exit 1
}

# Output error messages
function err_msg() {
    echo "`basename $0` (`date`): $1" >> $UNISYNC_LOG
    echo "`basename $0` (`date`): $1" 1>&2
}

# Output log messages
function log_msg() {
    echo "`basename $0` (`date`): $1" >> $UNISYNC_LOG
    echo "`basename $0` (`date`): $1"
}

function kill_open_connections () {
    # Kill any open connections 
    for conn_file in `ls $connection_dir`
    do
        target=$(echo $conn_file | sed -r 's/(.*)-[0-9]+$/\1/')
        target_port=$(echo $conn_file | sed -r 's/.*-([0-9]+)$/\1/')
        pid=$(cat $connection_dir/$conn_file)
        
        log_msg "Killing (possibly old) connection to $target:$target_port"
        
        if ( ps --pid $pid -o cmd | tail -n 1 | egrep "$connect_cmd_name\s+$target\s+$target_port" &> /dev/null )
        then
            kill $pid
        fi

        rm -f $connection_dir/$conn_file
    done
}

touch $pid_file
old_pid=`cat $pid_file`
if [ ! -z $old_pid ]
then
    echo "Old PID found... $old_pid"
    if ( ps --pid $old_pid -o cmd | tail -n 1 | egrep "$0$" )
    then
        err_msg "Unisync client is already running! (PID: $old_pid)"
        exit 2
    fi
fi

trap cleanup INT TERM EXIT

mkdir -p $UNISYNC_DIR

# Quit if there is no user configuration
if [ ! -f $user_conf_file ]
then
    err_msg "No user config found. Please add the configuration to $user_conf_file"
    cp $blank_user_conf $user_conf_file
    exit 1
fi

echo $$ > $pid_file

# Make all required directories
mkdir -p $targets_dir
mkdir -p $connection_dir


# Cleanup stale targets
rm -rf $targets_dir/*

kill_open_connections

log_msg "Starting lsync..."
lsyncd -log all $etc_dir/unisync-client.lua
err_msg "lsyncd died"

# Remove dead targets
rm -rf $targets_dir/*

kill_open_connections

trap - EXIT
