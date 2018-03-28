#!/bin/sh

names=`env | grep CUSTOM_CONFIG_ | sed 's/=.*//'`
if [ "$names" != "" ]; then
  while read name; do
    eval value='$'"${name}"
    echo "${value}" >> /etc/httpd/modsecurity.d/owasp-crs/crs-setup.conf
  done <<< "$names"
fi
