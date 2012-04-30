
bin_SCRIPTS = unisync-client

CLEANFILES = $(bin_SCRIPTS)

pkgsysconfdir = $(sysconfdir)/$(PROGRAM)

do_subst = sed -i -e 's,[@]pkgsysconfdir[@],$(pkgsysconfdir),g' \
			      -e 's,[@]VERSION[@],$(VERSION),g' \
				  -e 's,[@]program_transform_name[@],$(program_transform_name),g'

$(bin_SCRIPTS): %: %.sh
	rm -f $@
	echo "#! " $(BASH) > $@
	cat $^ >> $@
	$(do_subst) $@
	chmod u+x $@
