#!/bin/sh
#
# Filename: swatch_rhel_install.sh
# Author: Aaron Hung
# Data Written: 4/19/15
# Purpose: Installation script for SWATCH
#
# Description: Installs SWATCH perl dependencies. Downloads SWATCH into the /opt/src #	       directory. Builds SWATCH into the /opt/work/swatch directory.
#
# *** This script was written for use with RHEL Linux Distrobutions, CentOS 6.6 in particular **
# *** Tested with CentOS 6.6 ***
# Last Tested: 4/23/15

# Beginning of Script

# Welcome message
printf '\n Welcome to the SWATCH installation script!\n\n'

# Preliminary
cwd=`pwd`

# Install Dependencies
printf '\n Installing dependencies!\n\n'
yum install -y perl-cpan perl-Date-Calc-6.3-2.el6.noarch perl-TimeDate-1.16-13.el6.noarch perl-Date-Manip-6.24-1.el6.noarch perl-Time-HiRes-1.9721-136.el6_6.1.i686 &> /dev/null
error=$?

if [ $error -ne 0 ];
then
	echo " Error: Could not successfully install dependencies with yum!"
	exit 1
fi

cpan File::Tail
error=$?

if [ $error -ne 0 ];
then
	echo " Error: Could not successfully install dependency File::Tail with cpan!"
	exit 1
fi

printf '\n Finished installing dependencies!\n'
# Install SWATCH
# Untars SWATCH in /opt/src and installs SWATCH in /opt/work/
printf '\n Downloading and Installing SWATCH into /opt/work/swatch\n'
mkdir -p /opt/src
mkdir -p /opt/work

wget 'http://downloads.sourceforge.net/project/swatch/swatch/3.2.3/swatch-3.2.3.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fswatch%2F&ts=1429838692&use_mirror=softlayer-dal' -O /opt/src/swatch.tar.gz

tar -zxvf /opt/src/swatch.tar.gz -C /opt/work/

swatchVer=`ls /opt/work | grep swatch-.*$`
ln -s /opt/work/$swatchVer /opt/work/swatch

# Make SWATCH
cd /opt/work/swatch
perl Makefile.PL
make && make test && make install && make realclean &> /dev/null
if [ $error -ne 0 ];
then
	echo " Error: Could not compile swatch!"
	exit 1
fi

# Return to old current working directory
cd $cwd

# Exit message
printf '\n Finished installation of SWATCH!\n'
printf ' Installation directory can be found at /opt/work/swatch/\n'
printf ' Enjoy!\n'

exit 0
# End of Script
