#!/bin/sh
#
# Build RPMs from spec file + sources using mock
#
# Collect target platform, SPEC file and sources location from command line
target=$1
spec=$2
sources=$3
if [ -z "$target" ] || [ -z "$spec" ] || [ -z "$sources" ] ; then
    echo Usage: `basename $0` TARGET SPECFILE SOURCES
    exit
fi
# Check inputs
if [ ! -f /etc/mock/${target}.cfg ] ; then
    echo No cfg file for $target in /etc/mock/
    exit 1
fi
if [ ! -f $spec ] ; then
    echo SPEC file $spec not found
    exit 1
fi
if [ ! -d $sources ] ; then
    echo SOURCES directory $sources not found
    exit 1
fi
# Create SRPM
mock -r $target --buildsrpm --spec $spec --sources $sources
if [ $? != 0 ] ; then
    echo mock exited with an error building SRPM
    exit 1
fi
# Copy SRPM to central location
srpm=`ls /var/lib/mock/$target/result/*.src.rpm`
if [ -f "$srpm" ] ; then
    echo $srpm
    if [ ! -d $HOME/mock/$target ] ; then
	mkdir -p $HOME/mock/$target
    fi
    /bin/cp $srpm $HOME/mock/$target
else
    echo Source RPM not found in /var/lib/mock/$target/result/
    exit 1
fi
# Create RPMs from SRPM
mock -r $target --rebuild $HOME/mock/$target/`basename $srpm`
if [ $? != 0 ] ; then
    echo mock exited with an error building RPMs
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
    /bin/cp $rpm $HOME/mock/$target
done
echo Done