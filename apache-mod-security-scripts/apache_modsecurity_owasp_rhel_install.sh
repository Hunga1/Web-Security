#!/bin/sh
#
# Filename: apache_modsecurity_owasp_rhel_install.sh
# Author: Aaron Hung
# Data Written: 4/18/15
# Purpose: Apache Mod Security with OWASP Core Rule Set installation script for RHEL Linux.
#
# Description: Installs Apache Mod Security module configured to use OWASP Core Rule Set (CRS) for RHEL Linux.
#	       These rules protect a web application server from common attacks through a web application firewall.
#	       The firewall is configured by default to detect and block attacks, check the body of incomming 
#	       requests, and analyze the server's response bodies for vulnerabilities.
#
# *** This script was written for use with RHEL Linux Distrobutions, CentOS 6.6 in particular **
# *** Tested with CentOS 6.6 ***
# *** Last Tested: 4/22/15

# Beginning of Script

echo " Welcome to the Apache Mod Security with OWASP CRS installation script!"
printf '\n Checking preliminary details about your system...\n'

# Preliminary Checks
# Check if httpd directory exists
ls -d /etc/httpd > /dev/null &> /dev/null
error=$?
if [ $error -ne 0 ];
then
	echo " Error: /etc/httpd directory not found or does not exist!"
	logger -t modsecurity_install -p user.crit /etc/httpd directory not found!
	exit 1
fi 

printf ' Finished preliminary checks.\n'

# Install dependencies for Apache Mod_Security
printf '\n Installing Dependencies!\n'
yum install -y gcc make libxml2 libxml2-devel httpd-devel pcre-devel curl-devel git &> /dev/null
error=$?
if [ $error -ne 0 ];
then
	echo " Error: Dependencies could not be installed successfully!"
	logger -t modsecurity_install -p user.crit Dependencies could not be installed successfully!
	exit 1
fi

printf ' Finished installing dependencies.\n'

# Restart httpd
printf '\n Restarting Apache!\n'
service httpd restart &> /dev/null
error=$?
if [ $error -ne 0 ];
then
	echo " Error: Apache web server could not be restarted!"
	logger -t modsecurity_install -p user.crit Apache web server could not be restarted!
	exit 1
fi

# Install OWASP CRS from source through git repository
printf '\n Installing OWASP Core Rule Set!\n'
mkdir /etc/httpd/modsecurity-crs
git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /etc/httpd/modsecurity-crs &> /dev/null

# Rename example configuration, removing "example" extension for use with ModSecurity
mv /etc/httpd/modsecurity-crs/modsecurity_crs_10_setup.conf.example /etc/httpd/modsecurity-crs/modsecurity_crs_10_setup.conf

# Configure Apache to load OWASP CRS on startup
# Appends directive to /etc/httpd/conf/httpd.conf configuration file
printf '\n Configuring OWASP Core Rule Set to load on server startup!\n'
printf "\n<IfModule security2_module>\n\tInclude modsecurity-crs/modsecurity_crs_10_setup.conf\n\tInclude modsecurity-crs/base_rules/*.conf\n</IfModule>\n" >> /etc/httpd/conf/httpd.conf

printf ' Finished installing OWASP Core Rule Set!\n'

# Restart httpd
printf '\n Restarting Apache!\n'
service httpd restart &> /dev/null
error=$?
if [ $error -ne 0 ];
then
	echo " Error: Apache web server could not be restarted!"
	logger -t modsecurity_install -p user.crit Apache web server could not be restarted!
	exit 1
fi

# Make "whitelist" file to further configure OWASP rules
# Stores configuration in a seperate configuration directory and file (/etc/httpd/modsecurity.d/whitelist.conf)
printf '\n Configuring OWASP Core Rule Set!\n'
mkdir /etc/httpd/modsecurity.d
touch /etc/httpd/modsecurity.d/whitelist.conf

# Default whitelist configurations
#
# SecRuleEngine On
#	Detect and block any malicious attacks detected against server
# SecRequestBodyAccess On
#	Check server request bodies for malicious activity
# SecResponseBodyAccess On
#	Check server response bodies for malicious activity
# SecDataDir /etc/httpd/logs
#	Set where ModSecurity's working directory will be for persistent data
printf "# Whitelist Configuration File\n# Use to configure OWASP CRS and/or ModSecurity Firewall\n\n# OWASP CRS Configuration\n<IfModule mod_security2.c>\n\tSecRuleEngine On\n\tSecRequestBodyAccess On\n\tSecResponseBodyAccess On\n\tSecDataDir /etc/httpd/logs\n</IfModule>\n" > /etc/httpd/modsecurity.d/whitelist.conf

printf ' Finished configuring OWASP Core Rule Set!\n'

# Restart httpd
printf '\n Restarting Apache!\n'
service httpd restart &> /dev/null
error=$?
if [ $error -ne 0 ];
then
	echo " Error: Apache web server could not be restarted!"
	logger -t modsecurity_install -p user.crit Apache web server could not be restarted!
	exit 1
fi

# Exit on success
printf '\n Finished installing Apache Mod Security and OWASP Core Rule Set!\n Enjoy!\n\n'
exit 0

# End of script
