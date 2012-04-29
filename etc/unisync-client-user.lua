
-- Add syncs here
-- client_update: always include this parameter. It is the default
--                unisync mode
--
-- source:        the root directory of the sync on the local machine
--
-- target:        the name of the sync on the target host
--
-- targethost:    the remote host
--
-- targetport:    the ssh port or the remote host
--
-- excludes       lsyncd-style excludes for paths that shouldn't be
--                synced
--
-- unisonOpts     (untested) Extra options that can be passed to unison
--                for syncing. This can allow access to all of
--                unison's features (ie. more specific excludes, etc)
 
sync {
    client_update,
    source="",
    target="",
    targethost="",
    targetport="",
    exclude={""},
    unisonOpts={},
}