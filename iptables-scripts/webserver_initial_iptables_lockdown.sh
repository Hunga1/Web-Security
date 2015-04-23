#!/bin/sh
#
# Filename: webserver_initial_iptables_lockdown.sh
# Author: Aaron Hung
# Data Written: 4/18/15
# Purpose: Lockdown of web server environment when server instance is initially up
#
# Description: Flushes any preexisting IPtables firewall rules and installs a locked down 
#	       host firewall rule only open to HTTP,HTTPS, and SSH (optional) traffic. This
#	       is intended to be a starting point to built upon the firewall, whitelisting 
#	       services as they are needed, as your development web application grows to need 
#	       them.
#
# *** This script was written for use with RHEL Linux Distrobutions, CentOS 6.6 in particular **
# *** Tested with CentOS 6.6 ***
# *** Last Tested: 4/22/15

# Welcome Screen
printf '\n ***************************************\n ********* Web Server Lockdown *********\n ***************************************\n\n'

# Create directory to store old iptables rules
mkdir -p /tmp/iptables-old

# Preliminary User Inputs
# SSH port
error=1
while [ "$error" -eq 1 ];
do
	read -p ' Are you currently using SSH, or would you like to open a port for SSH traffic? (y/n) ' ssh_d_port

	if [ "$ssh_d_port" = "y" ];
	then
		printf '\n *** Caution, entering the wrong port could get you locked out!!! ***'
		printf '\n Please enter the port number: '
		read sshPort
		error=0
	elif [ "$ssh_d_port" = "n" ]
	then
		printf '\n Not setting SSH port\n'
		error=0
	fi
done


# SSH source address
error=1
if [ "$ssh_d_port" = "y" ];
then
	while [ "$error" -eq 1 ];
	do
		read -p ' Would you like to specify a source IP address as well? (y/n) ' ssh_s_ip
		if [ "$ssh_s_ip" = "y" ];
		then
			printf '\n *** Caution, entering the wrong ip address could get you locked out!!! ***'
			printf '\n Please enter the ip address: '
			read sshIP
			error=0
		elif [ "$ssh_s_ip" = "n" ]
		then
			printf '\n Not setting SSH source IP\n'
			error=0
		fi
	done
fi


# Save and flush any old rules

printf '\n Flushing old rules! Storing in: /tmp/iptables-old/\n'

iptables-save > /tmp/iptables-old/iptables-backup-`date +%y%m%d`.rules
iptables -F
error=$?
if [ $error -ne 0 ];
then
	echo " Error: Could not flush existing IPtables rules! Please check permissions."
	logger -t iptables_lockdown -p user.crit IPtables could not be flushed!
	exit 1
fi

# Default Rules
# Accept previously established or related connections, like your current SSH session
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Incoming NEW tcp packets must be SYN packets
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP

# Common Attack Prevention Rules
# XMAS attack
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

# Smurf attack
# Limit ICMP packet flow to 1 per second
iptables -A INPUT -p icmp -m icmp --icmp-type address-mask-request -j DROP
iptables -A INPUT -p icmp -m icmp --icmp-type timestamp-request -j DROP
iptables -A INPUT -p icmp -m icmp -m limit --limit 1/second -j ACCEPT

# Null Packets
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# Drop all invalid packets
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A OUTPUT -m state --state INVALID -j DROP

# Accept Localhost traffic
iptables -A INPUT -i lo -j ACCEPT

# HTTP/HTTPS traffic
iptables -A INPUT -p tcp -m state --state NEW -m multiport --dports 80,443 -j ACCEPT

# Last warning for SSH option
error=1
printf '\n Last warning!\n'

if [ "$ssh_d_port" = "y" ];
then
	echo " SSH port: $sshPort"
	if [ "$ssh_s_ip" = "y" ];
	then
		echo " SSH source ip: $sshIP"
	else
		echo " Not filtering for SSH source port."
	fi
else
	echo " You have not elected to open firewall to SSH traffic!"
fi

while [ "$error" -eq 1 ];
do
	read -p ' Continue? (y/n) ' yn
	if [ "$yn" = "n" ];
	then
		printf '\n Flushing firewalls and exiting!\n'
		iptables -F
		iptables-restore < /tmp/iptables-backup-`date +%y%m%d`.rules
		exit 0
	elif [ "$yn" = "y" ]
	then
		printf '\n Okay... Continuing!\n\n'
		error=0
	fi
done

# SSH traffic
# User-defined rule
if [ "$ssh_d_port" = "y" ];
then
	if [ "$ssh_s_ip" = "y" ];
	then
		iptables -A INPUT -p tcp -m state --state NEW --dport $sshPort -s $sshIP -j ACCEPT
	else
		iptables -A INPUT -p tcp -m state --state NEW --dport $sshPort -j ACCEPT
	fi
fi

# End of firewall rules
# Drop all other incomming traffic
iptables -A INPUT -j DROP

# Save firewall rules in /etc/sysconfig/iptables
#service iptables save

# Save firewall rules in /tmp/iptables-old
iptables-save > /tmp/iptables-old/iptables-`date +%y%m%d`.rules

# Save firewall rules to apply at startup
service iptables save

# Restart iptables
service iptables restart &> /dev/null

# Print IPtables rules
iptables -L --line-numbers --numeric

# Delete old Iptables rules
#rm -r /tmp/iptables-old

# Exit message
printf '\n ***************************************\n ********** Finished Lockdown **********\n ***************************************\n\n'
exit 0
# End of script
