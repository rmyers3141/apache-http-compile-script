#!/bin/bash
APACHE_USER=${APACHE_USER:=apache}
APACHE_GROUP=${APACHE_USER:=apache}
APACHE_ROOT=/apps/apache/2.4.29

rm -rf /apps/apache
rm -rf /kits/apache/install/*


firewall-cmd --zone=public --remove-service=http
firewall-cmd --zone=public --remove-service=https

systemctl disable apache.service
rm -f /etc/systemd/system/apache.service
