#!/bin/bash

# installnode
#
# set up config so that a node can be rebooted
# and installed with an operating system
#
# Written by Brett Pemberton, brett@vpac.org
# Copyright (C) 2004 Victorian Partnership for Advanced Computing

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

versions=$(for file in /tftpboot/pxelinux.cfg/install.*; do basename $file | awk -F"install." '{print $2}'; done)

if [ $# -ne 2 ]
then
	echo "$0 <node name> <install version>"
	echo
	echo "where install version is one of:"
	echo $versions
	exit 1
fi

node=$1
version=$2

if [ ! -f /tftpboot/pxelinux.cfg/install.$version ]
then
	echo "Version $version is not installable"
	echo "{file /tftpboot/pxelinux.cfg/install.$version does not exist}"
	echo "possible install versions are:"
	echo $versions
	exit 1
fi

ipaddr=$(egrep -w "$node" /etc/hosts | grep -v "${node}-" | awk '{print $1}')

if [ -z $ipaddr ]
then
	echo "Node $node does not resolve"
	echo "Please add it to /etc/hosts, and try again"
	exit 1
fi

if [ `grep -c -w "$ipaddr" /etc/dhcpd.conf` -eq 0 ]
then
	echo "Node $node is not in /etc/dhcpd.conf"
	echo "Add it with a static ip, and try again"
	exit 1
fi

echo "Installing node $node [$ipaddr] with version $version"

setboot $node install.$version

echo "..."
echo "Set up completed.  Please reboot node: $node"
echo "..."

while [ `tail -n 10 /var/log/messages | grep -c "DHCPOFFER on $ipaddr"` -eq 0 ]
do
	sleep 1
done

echo "Node has been rebooted, install in progress"

sleep 10

setboot $node localboot

