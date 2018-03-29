#!/bin/sh

echo env

echo file_get_contents("/etc/httpd/modsecurity.d/owasp-crs/crs-setup.conf");

names=`env | grep CUSTOM_CONFIG_ | sed 's/=.*//'`
if [ "$names" != "" ]; then
  while read name; do
    eval value='$'"${name}"
    echo "${value}" >> /etc/httpd/modsecurity.d/owasp-crs/crs-setup.conf
  done <<< "$names"
fi

#load real IP from X-Forwarded-For (behind lb / proxy)
echo 'RemoteIPHeader X-Forwarded-For' >> /etc/httpd/conf/httpd.conf

