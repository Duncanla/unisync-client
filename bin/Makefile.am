
bin_SCRIPTS = unisync-client

EXTRA_DIST = unisync-client.sh
CLEANFILES = $(bin_SCRIPTS)


pkgsysconfdir = $(sysconfdir)/$(PACKAGE)

do_subst = sed -i -e 's,[@]pkgsysconfdir[@],$(pkgsysconfdir),g' \
			      -e 's,[@]VERSION[@],$(VERSION),g'

conn_cmd = `echo unisync-client-connect | sed '$(program_transform_name)'`

cmd_subst = sed -i "s/[@]unisync-client-connect[@]/$(conn_cmd)/g"

$(bin_SCRIPTS): %: %.sh
	rm -f $@
	echo "#!" $(BASH) > $@
	cat $^ >> $@
	$(do_subst) $@
	$(cmd_subst) $@
	chmod u+x $@
