
pkgsysconfdir = $(sysconfdir)/$(PACKAGE)
pkgsysconf_DATA = unisync-client.lua unisync-client-user.lua unisync-client.conf

EXTRA_DIST = unisync-client.lua.in unisync-client-user.lua unisync-client.conf
CLEANFILES = unisync-client.lua

do_subst = sed -i -e 's,[@]pkgsysconfdir[@],$(pkgsysconfdir),g' \
			      -e 's,[@]VERSION[@],$(VERSION),g' \
				  -e 's,[@]pkglibexecdir[@],$(pkglibexecdir),g' \
				  -e 's/[@]program_transform_name[@]/$(program_transform_name)/g'

sync_name = `echo unisync-client-sync | sed '$(program_transform_name)'`
syncinit_name = `echo unisync-client-syncinit | sed '$(program_transform_name)'`


unisync-client.lua: %: %.in
	rm -f $@
	cat $^ >> $@
	$(do_subst) $@
	sed -i "s/[@]unisync-client-sync[@]/$(sync_name)/" $@
	sed -i "s/[@]unisync-client-syncinit[@]/$(syncinit_name)/" $@
	chmod u+x $@
