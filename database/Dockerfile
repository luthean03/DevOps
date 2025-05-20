FROM postgres:17.2-alpine

# copy all .sql scripts into the init folder
COPY initdb/*.sql /docker-entrypoint-initdb.d/
