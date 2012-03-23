#!/bin/sh
#
# Build RPMs from SRPMs using mock
#
# Collect target platform and SRPM from command line
target=$1
srpm=$2
if [ -z "$target" ] || [ -z "$srpm" ] ; then
    echo Usage: `basename $0` TARGET SRPM
    exit
fi
# Check inputs
if [ ! -f /etc/mock/${target}.cfg ] ; then
    echo No cfg file for $target in /etc/mock/
    exit 1
fi
if [ ! -f $srpm ] ; then
    echo SRPM $srpm not found
    exit 1
fi
# Run rebuild
mock -r $target --rebuild $srpm
if [ $? != 0 ] ; then
    echo mock exited with an error rebuilding from SRPM
    exit 1
fi
# Copy RPMs to central location
rpms=`ls /var/lib/mock/$target/result/*.rpm | grep -v debuginfo`
if [ -z "$rpms" ] ; then
    echo No RPMs found in /var/lib/mock/$target/result/
    exit 1
fi
for rpm in $rpms ; do
    echo $rpm
    if [ ! -d $HOME/mock/$target ] ; then
	mkdir -p $HOME/mock/$target
    fi
    /bin/cp $rpm $HOME/mock/$target
done
echo Done
