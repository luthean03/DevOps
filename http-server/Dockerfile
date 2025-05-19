FROM httpd:2.4-alpine

# Copy your customized Apache config
COPY httpd.conf /usr/local/apache2/conf/httpd.conf

# Copy your landing page
COPY index.html /usr/local/apache2/htdocs/index.html

EXPOSE 80
