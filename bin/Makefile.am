
bin_SCRIPTS = unisync-client

CLEANFILES = $(bin_SCRIPTS)

pkgsysconfdir = $(sysconfdir)/$(PROGRAM)

do_subst = sed -i -e 's,[@]pkgsysconfdir[@],$(pkgsysconfdir),g' \
			      -e 's,[@]VERSION[@],$(VERSION),g'

conn_cmd = `echo unisync-client-connect | sed '$(program_transform_name)'`

$(bin_SCRIPTS): %: %.sh
	rm -f $@
	echo "#!" $(BASH) > $@
	cat $^ >> $@
	$(do_subst) $@
	sed -i "s/[@]unisync-client-connect[@]/$(conn_cmd)/g" $@
	chmod u+x $@
