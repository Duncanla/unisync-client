# -* bash -*

#
# Unisync client connect
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

target_host=$1
shift
target_port=$1
shift

connection_dir=$UNISYNC_DIR/connections
connection_file=$connection_dir/$target_host-$target_port

targets_dir=$UNISYNC_DIR/targets
target_dir=$targets_dir/$target_host-$target_port
port_file=$target_dir/client_port
status_file=$target_dir/client_conn_status
client_dir=$target_dir/clients
autossh_pid_file=$target_dir/autossh.pid
mkdir -p $target_dir
echo 0 > $target_dir/client_conn_status

# Cleanup for trapped signals
function cleanup {
    rm -f $status_file
    rm -f $client_dir/*
    rm -f $connection_file

    # Kill any background jobs
    ps --pid $(jobs -p) &> /dev/null && kill $(jobs -p)

    # Kill auto ssh with SIGKILL if needed. It can be stubborn
    # when it is called with AUTOSSH_GATETIME=0
    ps --pid $autossh_pid &> /dev/null && kill -9 $autossh_pid

    err_msg "Died!"
    
    # Clear the trap on exit so we don't triger a second trap
    trap - EXIT
    exit 500
}

# Output to log file
function err_msg() {
    echo "`basename $0` (`date`): $1" >> $UNISYNC_LOG
    echo "`basename $0` (`date`): $1" 1>&2
}

# Output to log file
function log_msg() {
    echo "`basename $0` (`date`): $1" >> $UNISYNC_LOG
    echo "`basename $0` (`date`): $1"
}

# Kill existing autossh process for this target
touch $autossh_pid_file
autossh_cmd_check="autossh -M 0 -p $target_port $target_host $TARGET_PORT_CMD"
oldpid=`cat $autossh_pid_file`
if [ -f $autossh_pid_file ]
then
    if [ "`ps -o args $oldpid | tail -n 1`" = "$autossh_cmd_check" ]
    then
        log_msg "Killing old autossh process: $oldpid"
        # Must use SIGKILL when calling autossh with AUTOSSH_GATETIME=0
        kill -9 $oldpid
    fi
fi

trap cleanup INT TERM EXIT

echo $$ > $connection_file

while true
do
    # Request to open a port from the target_host. Exit with 255 to tell autossh to try again
    AUTOSSH_GATETIME=0 AUTOSSH_POLL=60 AUTOSSH_PIDFILE=$autossh_pid_file autossh -M 0 -p $target_port $target_host "$TARGET_PORT_CMD || exit 255" > $port_file &
    autossh_pid=$!

    wait $autossh_pid
    port=$(cat $port_file)

    echo 1 > $status_file
    log_msg "CONNECTED to $target_host:$target_port. Using reverse tunneling on target port $port"

    # Open up the client monitor connection
    log_msg "Starting monitor on $target_host:$target_port"
    ssh -p $target_port -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -R$port:localhost:22 $target_host "$TARGET_MON_CMD $port" &
    ssh_pid=$!


    # Re-register clients with the target_host
    if `ls $client_dir/client-* &> /dev/null`
    then
        for client_file in $client_dir/client-*
        do
            client_options=\"$(cat $client_file | sed -r "s/<UNISYNC_CLIENT_PORT>/$port/")\"
            log_msg "Registering initialized client: $client_file"
            log_msg "With options: $client_options"
            if ! (ssh -p $target_port $target_host $TARGET_CLIENT_REG_CMD $port $client_options)
            then
                log_msg "Unable to register initialized client: $client_file"
                kill $ssh_pid
            else
                log_msg "Successfully registered initialized client: $client_file"
            fi
        done
    fi
    
    # Ignore errors on the client monitor as it will return nonzero exit code when the connection drops
    set +e
    wait $ssh_pid
    set -e

    echo 0 > $status_file
    log_msg "DISCONNECTED from $target_host:$target_port"
done

rm -f $status_file
rm -f $client_dir/*
rm -f $connection_file





