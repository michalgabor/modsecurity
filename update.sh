#!/bin/sh

names=`env | grep CUSTOM_CONFIG_ | sed 's/=.*//'`
if [ "$names" != "" ]; then
  while read name; do
    eval value='$'"${name}"
    echo "${value}" >> /etc/httpd/modsecurity.d/owasp-crs/crs-setup.conf
  done <<< "$names"
fi

sed -i -e "s/remote_addr/x_forwarded_for/g" /etc/httpd/modsecurity.d/owasp-crs/rules/REQUEST-901-INITIALIZATION.conf

