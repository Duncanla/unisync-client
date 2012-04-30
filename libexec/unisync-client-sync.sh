# -* bash -*

#
# Unisync client sync
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

cmd=$0
target_host=$1
shift
target_port=$1
shift
root1_dir=$1
shift
target_id=$1
shift
options="$@"

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

log_msg "Syncing $target_host:$target_port"
log_msg "Options: $options"

targets_dir=$UNISYNC_DIR/targets
target_dir=$targets_dir/$target_host-$target_port
status_file=$target_dir/client_conn_status
port_file=$target_dir/client_port

conn_status=`head -n 1 $status_file`
if [ $conn_status -ne 1 ]
then
    log_msg "Not connected to server. Not syncing"
    exit 0
fi

port=`head -n 1 $port_file`

target_sync_req_cmd="unisync-sync-req"

client_options=`echo "-root ssh://localhost:$port/$root1_dir -targetid $target_id $options"`
# make sure the shell doesn't mess with our options 
target_client_options=\'$client_options\'

# request a sync
ssh -p $target_port $target_host "$target_sync_req_cmd $port $target_client_options"

log_msg "Initiated request for sync."
