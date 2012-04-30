# -* bash -*

#
# Unisync client sync initialization
# 
# Copyright (c) 2012, Luke Duncan <Duncan72187@gamil.com>
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
root1_dir=$1
shift
target_id=$1
shift
options="$@"

# Cleanup for trap signals
function cleanup() {
    if [ -f $lockfile ]
    then
        if [[ `head -n 1 $lockfile` -eq $$ ]]
        then
            rm -f $lockfile
        fi
    fi

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

log_msg "Initializing sync to $target_host:$target_port"
log_msg "Roots: $root1_dir -> $target_id"
log_msg "Options: $options"

targets_dir=$UNISYNC_DIR/targets
target_dir=$targets_dir/$target_host-$target_port
status_file=$target_dir/client_conn_status
client_dir=$target_dir/clients

connect_cmd=unisync-client-connect
target_reg_client_cmd="unisync-reg-client"

port_file=$target_dir/client_port

mkdir -p $target_dir
touch $status_file

# Check the connection status -- connect to host if needed
conn_status=`head -n 1 $status_file`
if [ "x$conn_status" = "x" ]
then
    log_msg "Not connected to target_host... attempting to connect..."
    $connect_cmd $target_host $target_port &
    sleep 5
    conn_status=`head -n 1 $status_file`
fi

trap cleanup INT TERM EXIT

# Make sure we don't have colliding requests for new clients
lockfile=$target_dir/client_lock
lock_tries=0
while ! ( set -o noclobber; echo "$$" > "$lockfile") &> /dev/null
do
    if [[ $lock_tries -eq 0 ]]
    then
        log_msg "Waiting on lock $lockfile"
    fi
    lock_tries=$lock_tries+1
    sleep 1
done


#Save the client information on the local computer using placeholder for port
port="<UNISYNC_CLIENT_PORT>"
mkdir -p $client_dir
client_file=$(echo $client_dir/client-`ls $client_dir | egrep -c client-.+`)
touch $client_file

# Make sure we aren't duplicating a left-over client file
client_options=`echo "-root ssh://localhost:$port/$root1_dir -targetid $target_id $options"`
for cfile in $client_dir/client-*
do
    if [ "`cat $cfile`" = "$client_options" ]
    then
        log_msg "Client file $cfile already created"
        rm $client_file
        client_file=$cfile
        break;
    fi
done
echo "$client_options" > $client_file

# Die if we aren't connected
conn_status=`head -n 1 $status_file`
if [ $conn_status -ne 1 ]
then
    err_msg "Sync not registered with server -- Not connected" 
    trap - EXIT
    exit 0
fi

# If we are connected, read the id and register the
# client and a new sync request with the host
port=`head -n 1 $port_file`

rm -f $lockfile
trap - INT TERM EXIT

# make sure the shell doesn't mess with our options 
target_client_options=\'$(echo $client_options | sed "s/<UNISYNC_CLIENT_PORT>/$port/")\'

# register the client with the server
log_msg "Registering with the $target_host:$target_port with reverse forwarding port $port"
log_msg "and options $target_client_options"
ssh -p $target_port $target_host "$target_reg_client_cmd $port $target_client_options"
log_msg "Client registration returned with exit status $?"

trap - EXIT
