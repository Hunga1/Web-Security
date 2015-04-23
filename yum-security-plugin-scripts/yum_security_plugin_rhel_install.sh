#!/bin/sh
#
# Filename: yum_security_plugin_rhel_install.sh
# Author: Aaron Hung
# Data Written: 4/19/15
# Purpose: Automate updating of packages tracked by yum with updates related to security
#
# Description: 
#
# *** This script was written for use with RHEL Linux Distrobutions, CentOS 6.6 in particular **
# *** Tested with CentOS 6.6 ***
# *** Last Tested: 4/22/15

# Welcome message
printf '\n Welcome to the Yum Security Plugin Installation Script!\n'

# Install yum security plugin
printf '\n Installing yum security plugin\n'
yum install -y yum-plugin-security &> /dev/null
success=$?
if [ $success -ne 0 ];
then
	echo "Error: Could not install yum security plugin from yum repositories!"
	exit 1
fi

# User configuration options
# Email results of yum
error=1
while [ "$error" -eq 1 ];
do
	read -p ' Would you like yum update results to be emailed to you? (y/n) ' emailYN
	if [ "$emailYN" = "y" ];
	then
		read -p ' Enter email: ' email
		sed -i -e "s/MAILTO.*/MAILTO=$email/" /etc/crontab
		error=0
	elif [ "$emailYN" = "n" ];
	then
		error=0
	fi
done

# Find user interval to run yum security update
# Minute
regex='^([1-9]|0[1-9]|[1-5][1-9])$'
error=1
while [ "$error" -eq 1 ];
do
	printf '\n What minute would you like to update?\n'
	printf ' (0 - 59) or * for every minute\n'
	read minute
	if [[ $minute =~ $regex ]] && [ "$minute" != "*" ];
	then
		echo "Invalid input!, Try again"
	else
		error=0
	fi
done

# Hour
regex='^([0-9]|0[1-9]|1[0-9]|2[0123])$'
error=1
while [ "$error" -eq 1 ];
do
	printf '\n What hour would you like to update?\n'
	printf ' (0 - 23) or * for every hour\n'
	read hour
	if [[ $hour =~ $regex ]] && [ "$hour" != "*" ];
	then
		echo "Invalid input!, Try again"
	else
		error=0
	fi
done

# Day of the month
regex='^([1-9]|[1-2][0-9]|3[01])$'
error=1
while [ "$error" -eq 1 ];
do
	printf '\n What day of the month would you like to update?\n'
	printf ' (1 - 31) or * for every day\n'
	read day
	if [[ $day =~ $regex ]] && [ "$day" != "*" ];
	then
		echo "Invalid input!, Try again"
	else
		error=0
	fi
done

# Month
regex='^([1-9]|1[0-2])$'
error=1
while [ "$error" -eq 1 ];
do
	printf '\n What month would you like to update?\n'
	printf ' (1 - 12) or * for every month\n'
	read month
	if [[ $month =~ $regex ]] && [ "$month" != "*" ];
	then
		echo "Invalid input!, Try again"
	else
		error=0
	fi
done

# Day of the week
regex='^([0-7])$'
error=1
while [ "$error" -eq 1 ];
do
	printf '\n What day of the week would you like to update?\n'
	printf ' (0 - 7)(Sunday = {0,7}) or * for every day of the week\n'
	read day_week
	if [[ $day_week =~ $regex ]] && [ "$day_week" != "*" ];
	then
		echo "Invalid input!, Try again"
	else
		error=0
	fi
done

# Add yum security update cronjob to crontab
whichYum=`which yum`
printf '\n# Run automated yum security update\n' >> /etc/crontab
echo "$minute $hour $day $month $day_week root $whichYum --security update-minimal" >> /etc/crontab
printf '\n' >> /etc/crontab

# Exit message
printf '\n Finished configuring cron to run yum security during set time'
printf '\n Current cron job set:\n\n'
tail -n 3 /etc/crontab
printf '\n Goodbye!\n\n'

exit 0
# End of script
