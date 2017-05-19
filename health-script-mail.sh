#!/bin/bash
# This script is to send email for the health check output
# This uses sendmail feature.

read -p "Enter Your Email: " TO
sed -r "s/\x1B\[(([0-9]{1,2})?(;)?([0-9]{1,2})?)?[m,K,H,f,J]//g" /home/admin/health-check.txt > /home/admin/health-check-1.txt
FROM=admin@$(hostname)
TO=$TO
BODY_FILE=/home/admin/health-check-1.txt

(cat - $BODY_FILE)<<HEADERS_END | /usr/sbin/sendmail -f $FROM -t $TO
Subject: VDP System Status
To: $TO
HEADERS_END

printf "\nMail Sent. All Done!\n\n"
rm /home/admin/health-check.txt
rm /home/admin/health-check-1.txt
