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

echo "Adjust access and error logs, shall go to stdout and stderr respectively"
sed -i".bak" "s,CustomLog \"logs/access_log\" combined,CustomLog \"/dev/stdout\" combined," /etc/httpd/conf/httpd.conf
sed -i".bak" "s,ErrorLog \"logs/error_log\",ErrorLog \"/dev/stderr\"," /etc/httpd/conf/httpd.conf

sed -i -e "s/LogLevel warn/LogLevel ${LOG_LEVEL}/g" /etc/httpd/conf/httpd.conf
echo "Set log level to '${LOG_LEVEL}'"

echo "Starting httpd"
httpd -D FOREGROUND
