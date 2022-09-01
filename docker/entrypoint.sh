#!/bin/bash

source /var/www/html/.env

if [ "${SITE_ACCESS_PASSWORD}" != "" ] && [ "${SITE_ACCESS_USER}" != "" ]; then
    echo ${SITE_ACCESS_PASSWORD}|htpasswd -i -c /etc/nginx/.htpasswd ${SITE_ACCESS_USER}
else
   touch /etc/nginx/.htpasswd
fi

export BASIC_AUTH_ENABLED=${BASIC_AUTH_ENABLED}
envsubst '${BASIC_AUTH_ENABLED}' < /etc/nginx/conf.d/default.conf > /etc/nginx/conf.d/default.conf.tmp
rm -rf /etc/nginx/conf.d/default.conf
mv /etc/nginx/conf.d/default.conf.tmp /etc/nginx/conf.d/default.conf

mkdir -p /var/www/html/storage/logs
chmod -R a+w /var/www/html/storage

if [ "$1" == "cron" ]; then
  echo "Run cron instance"
  cd /var/www/html
  echo "Apply migrations"
  #yes | /usr/local/bin/php artisan codenrock:start
  yes | /usr/local/bin/php artisan migrate
  yes | /usr/local/bin/php artisan sp:publish

  mkdir -p /var/www/html/storage/logs
  chmod -R a+w /var/www/html/storage

  envsubst '${SQS_QUEUE}' < /etc/supervisor/conf.d/supervisord.cron.conf >/etc/supervisor/conf.d/supervisord.cron.conf.tmp
  mv /etc/supervisor/conf.d/supervisord.cron.conf.tmp  /etc/supervisor/conf.d/supervisord.cron.conf

  /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.cron.conf
else
  echo "Run ordinary instance"
  sleep 30
  /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
  yes | /usr/local/bin/php artisan sp:publish
fi
