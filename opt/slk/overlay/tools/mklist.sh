#!/bin/bash

#export OVERLAY_ROOT=/opt/slk/overlay
#export UPSTREAM_ROOT=/opt/slk/upstream/source
#export WORK_ROOT=/opt/slk/work/tree

#export BUILDLIST=$OVERLAY_ROOT/config/build.lst

if [ ! -r $BUILDLIST ]; then
	echo "Could not find :: $BUILDLIST"
	echo "Creating :: $BUILDLIST"
	touch $BUILDLIST
else
	>$BUILDLIST
fi

echo ""
echo ">> Generating build order"

# By Slackware Package series
for series in $SERIES_LIST ; 
do
	for script in ${UPSTREAM_ROOT}/$series/*/*.SlackBuild ; do
		if [ "$(basename $(echo $script | cut -f 1 -d ' ') .SlackBuild)" = "$(echo $(dirname $(echo $script | cut -f 1	-d ' ')) | rev | cut -f 1 -d / | rev)" ]; then
			echo "$(echo $script | sed 's/\/opt\/slk\/upstream\/source\///g') "
			echo $(echo $script | sed 's/\/opt\/slk\/upstream\/source\///g') >> $BUILDLIST
		fi
	done
done

# No reason to harden the kernel firmware
sed -i '/a\/kernel-firmware\/kernel-firmware\.SlackBuild/d' $BUILDLIST

# TODO: Handle the kernel builds elsewhere
sed -i '/k\/kernel-generic\.SlackBuild/d' $BUILDLIST
sed -i '/k\/kernel-headers\.SlackBuild/d' $BUILDLIST
sed -i '/k\/kernel-source\.SlackBuild/d' $BUILDLIST

# Delete these. (From the make_world script)
sed -i '/a\/devs\/devs\.SlackBuild/d' $BUILDLIST
sed -i '/a\/isapnptools\/isapnptools\.SlackBuild/d' $BUILDLIST

# TODO: Delete for now.  Doesn't build in an lxc container
# See init scripts for lxc handling
# Use some logic to detect build environment
sed -i '/a\/splitvt\/splitvt\.SlackBuild/d' $BUILDLIST

# Move the kde main slackbuild to the end of the list
# Disabled for now. Need to squeeze this in some other way
if [ -r ${UPSTREAM_ROOT}/kde/kde/kde.SlackBuild ]; then
	# For now just remove kde mega slackbuild.
	sed -i '/kde\/kde\/kde\.SlackBuild/d' $BUILDLIST
	#echo "kde/kde/kde.SlackBuild" >> $BUILDLIST
fi

if [ "$?" -eq "0" ]; then
	echo "SlackBuilds Added :: $(cat $BUILDLIST | wc -l)"
else
	echo "<< Status :: Failed" 
	exit 1
fi
