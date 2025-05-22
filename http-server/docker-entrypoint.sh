#!/bin/sh

# Remplace ${CONTAINER_PROXY} dans le template
envsubst '$CONTAINER_BACKEND $CONTAINER_FRONTEND' \
  < /usr/local/apache2/conf/httpd.conf.template \
  > /usr/local/apache2/conf/httpd.conf

# Lance Apache normalement
exec httpd-foreground
