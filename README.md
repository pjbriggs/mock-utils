mock-utils
==========

Utility scripts for building RPMs using mock.

mockit.sh - build RPM for target platform
------------------------------------------

Usage: mockit.sh TARGET SPEC SOURCES [ RPM [ RPM ... ] ]

mockit.sh creates the SRPM and RPM for the specified platform TARGET (must be
one of the available /etc/mock/*.cfg files, or the path to a custom .cfg file),
given a SPEC file and directory SOURCES containing the required source archives
and patches etc.

If additional RPMs are specified on the command line then mockit.sh will put
these into a temporary repository which is made available to the mock build
environment. This provides a way of pulling in dependencies which aren't
available through the standard yum repositories (most likely because you've
built them yourself).

The generated SRPM and RPMs are put into $HOME/mock-rpms/TARGET

mock-rebuild.sh - rebuild RPM from SPRM
----------------------------------------

Usage: mock-rebuild.sh TARGET SRPM

mock-rebuild.sh generates the RPM for the specified platform TARGET (must be
one of the available /etc/mock/*.cfg files) given an existing SRPM.

The generated RPMs are put into $HOME/mock-rpms/TARGET

--
