FROM httpd:2.4-alpine

# Installer envsubst
RUN apk add --no-cache gettext

WORKDIR /usr/local/apache2

# Copier le template complet
COPY httpd.conf.template conf/httpd.conf.template

# Copier la landing page
COPY index.html htdocs/index.html

# Ajouter l’entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["httpd-foreground"]
