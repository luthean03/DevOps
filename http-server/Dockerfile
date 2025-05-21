FROM httpd:2.4-alpine

# Install envsubst for environment variable substitution
RUN apk add --no-cache gettext

WORKDIR /usr/local/apache2

# Copy the complete httpd configuration template
COPY httpd.conf.template conf/httpd.conf.template

# Copy the landing page
COPY index.html htdocs/index.html

# Add the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

# Set the entrypoint to the custom script
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command to start Apache in the foreground
CMD ["httpd-foreground"]
