#!/bin/bash

source /var/www/html/.env
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}

if [ "$BACKUP_BUCKET" == "" ]; then
  export BACKUP_BUCKET=codenrock-db-backup
fi

mkdir -p ~/.mysql && \
wget "https://storage.yandexcloud.net/cloud-certs/CA.pem" -O ~/.mysql/root.crt && \
chmod 0600 ~/.mysql/root.crt

mkdir -p /backup

mysqldump --insert-ignore --skip-lock-tables --single-transaction=TRUE  --host=${DB_HOST} --port=${DB_PORT} --ssl-ca=~/.mysql/root.crt --ssl-mode=VERIFY_IDENTITY --user=${DB_USERNAME} -p${DB_PASSWORD} ${DB_DATABASE} | gzip > /backup/${DB_DATABASE}.gz

/usr/local/bin/aws s3 cp /backup/${DB_DATABASE}.gz s3://${BACKUP_BUCKET}/${DB_DATABASE}.gz

rm /backup/${DB_DATABASE}.gz
