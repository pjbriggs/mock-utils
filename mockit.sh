#!/bin/sh
#
# Build RPMs from spec file + sources using mock
# It will also include any dependent RPMs explicitly specified on the
# command line
#
# Location to put the SRPM and RPM
mockdir=${HOME}/mock-rpms
# Collect target platform, SPEC file and sources location from command line
target=$1
spec=$2
sources=$3
if [ -z "$target" ] || [ -z "$spec" ] || [ -z "$sources" ] ; then
    echo "Usage: $(basename $0) TARGET SPECFILE SOURCES [ RPM [ RPM... ] ]"
    echo ""
    echo "TARGET:   target platform e.g. epel-6-x86_64 corresponding to a"
    echo "          cfg file in /etc/mock OR the name of a custom cfg file"
    echo "          (can include a leading path)"
    echo ""
    echo "SPECFILE: name/path of RPM spec file to build"
    echo ""
    echo "SOURCES:  directory containing source code archives, patch files"
    echo "          etc"
    echo ""
    echo "Subsequent arguments are optional and specify custom RPMs that"
    echo "are required to build this RPM."
    exit
fi
# Check inputs
cfg=${target}
if [ ! -f "$cfg" ] ; then
    # Not a file, trying current dir
    cfg=$(pwd)/${target}.cfg
    if [ ! -f "$cfg" ] ; then
	cfg=/etc/mock/${target}.cfg
	if [ ! -f "$cfg" ] ; then
	    echo Unable to locate cfg file for $target
	    exit 1
	fi
    fi
fi
if [ ! -f $spec ] ; then
    echo SPEC file $spec not found
    exit 1
fi
if [ ! -d $sources ] ; then
    echo SOURCES directory $sources not found
    exit 1
fi
# (Re)extract target platform name
target=$(basename ${cfg%.*})
# Check dependencies
dependencies=
while [ ! -z $4 ] ; do
    if [ -f $4 ] ; then
	dependencies="$dependencies $4"
    else
	echo WARNING $4 not found
    fi
    shift
done
if [ -z "$dependencies" ] ; then
    echo No dependencies specified/found
fi
# Create temporary directory
wd=`mktemp -d`
echo Temporary dir for cfg and mock-updates repo = $wd
# Copy the cfg files to working directory
cp /etc/mock/logging.ini $wd
cp /etc/mock/site-defaults.cfg $wd
cp ${cfg} $wd
# Report settings
cat <<EOF
Target platform: ${target}
Cfg file       : ${cfg}
Spec file      : ${spec}
Sources dir    : ${sources}
Dependencies   : ${dependencies}
Working dir    : ${wd}
EOF
# Create a temporary repo with the specified RPMs
if [ ! -z "$dependencies" ] ; then
    mkdir ${wd}/mock-updates
    for dep in $dependencies ; do
	cp $dep ${wd}/mock-updates
    done
    createrepo -q ${wd}/mock-updates # use -q to suppress output
    # Hack the cfg file to append the temporary repo
    grep -v '^"""' ${wd}/${target}.cfg > ${wd}/${target}.cfg.tmp
    mv ${wd}/${target}.cfg.tmp ${wd}/${target}.cfg
    cat >> ${wd}/${target}.cfg <<EOF

[mock-updates]
name=mock-updates
baseurl=file://${wd}/mock-updates
gpgcheck=0
"""
EOF
fi
# Create SRPM
mock --configdir=$wd -r $target --buildsrpm --spec $spec --sources $sources
if [ $? != 0 ] ; then
    echo mock exited with an error building SRPM
    /bin/rm -rf ${wd}
    exit 1
fi
# Copy SRPM to central location
srpm=`ls /var/lib/mock/$target/result/*.src.rpm`
if [ -f "$srpm" ] ; then
    echo $srpm
    if [ ! -d $mockdir/$target ] ; then
	mkdir -p $mockdir/$target
    fi
    /bin/cp $srpm $mockdir/$target
else
    echo Source RPM not found in /var/lib/mock/$target/result/
    /bin/rm -rf ${wd}
    exit 1
fi
# Create RPMs from SRPM
mock --configdir=$wd -r $target --rebuild $mockdir/$target/`basename $srpm`
if [ $? != 0 ] ; then
    echo mock exited with an error building RPMs
    /bin/rm -rf ${wd}
    exit 1
fi
# Copy RPMs to central location
rpms=`ls /var/lib/mock/$target/result/*.rpm | grep -v debuginfo`
if [ -z "$rpms" ] ; then
    echo No RPMs found in /var/lib/mock/$target/result/
    /bin/rm -rf ${wd}
    exit 1
fi
for rpm in $rpms ; do
    echo $rpm
    /bin/cp $rpm $mockdir/$target
done
# Clean up temporary directory
/bin/rm -rf ${wd}
echo Done
