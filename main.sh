#!/bin/sh

if [ "${SEC_RULE_ENGINE}" != "" ]; then
  sed -i".bak" "s/SecRuleEngine On/SecRuleEngine ${SEC_RULE_ENGINE}/" /etc/httpd/modsecurity.d/modsecurity.conf
  echo "SecRuleEngine set to '${SEC_RULE_ENGINE}'"
fi

if [ "${SEC_PRCE_MATCH_LIMIT}" != "" ]; then
  sed -i".bak" "s/SecPcreMatchLimit 1000/SecPcreMatchLimit ${SEC_PRCE_MATCH_LIMIT}/" /etc/httpd/modsecurity.d/modsecurity.conf
  echo "SecPcreMatchLimit set to '${SEC_PRCE_MATCH_LIMIT}'"
fi

if [ "${SEC_PRCE_MATCH_LIMIT_RECURSION}" != "" ]; then
  sed -i".bak" "s/SecPcreMatchLimitRecursion 1000/SecPcreMatchLimitRecursion ${SEC_PRCE_MATCH_LIMIT_RECURSION}/" /etc/httpd/modsecurity.d/modsecurity.conf
  echo "SecPcreMatchLimitRecursion set to '${SEC_PRCE_MATCH_LIMIT_RECURSION}'"
fi

if [ "${PROXY_UPSTREAM_HOST}" != "" ]; then
  sed -i".bak" "s/127.0.0.1:3000/${PROXY_UPSTREAM_HOST}/g" /etc/httpd/conf.d/proxy.conf
  echo "Upstream host set to '${PROXY_UPSTREAM_HOST}'"
fi

if [ "${CUSTOM_VHOST_CONFIG}" != "" ]; then
  sed -i".bak" "s/#/${CUSTOM_VHOST_CONFIG}/g" /etc/httpd/conf.d/proxy.conf
  echo "Custom proxy config '${CUSTOM_VHOST_CONFIG}'"
fi

echo "Adjust access and error logs, shall go to stdout and stderr respectively"
#disable access log via #CustomLog
sed -i".bak" "s,CustomLog \"logs/access_log\" combined,\#CustomLog \"/dev/stdout\" combined," /etc/httpd/conf/httpd.conf
sed -i".bak" "s,ErrorLog \"logs/error_log\",ErrorLog \"/dev/stderr\"," /etc/httpd/conf/httpd.conf

sed -i -e "s/LogLevel warn/LogLevel ${LOG_LEVEL}/g" /etc/httpd/conf/httpd.conf
echo "Set log level to '${LOG_LEVEL}'"

#custom config crs-setup.conf
names=`env | grep CUSTOM_CONFIG_ | sed 's/=.*//'`
if [ "$names" != "" ]; then
  while read name; do
    eval value='$'"${name}"
    grep -q -F "${value}" /etc/httpd/modsecurity.d/owasp-crs/crs-setup.conf || echo "${value}" >> /etc/httpd/modsecurity.d/owasp-crs/crs-setup.conf
  done <<< "$names"
fi

#load real IP from X-Forwarded-For (behind lb / proxy)
grep -q -F 'RemoteIPHeader X-Forwarded-For' /etc/httpd/conf/httpd.conf || echo 'RemoteIPHeader X-Forwarded-For' >> /etc/httpd/conf/httpd.conf

echo "Starting httpd"
httpd -D FOREGROUND
