# Use the official PostgreSQL 17.2 image based on Alpine Linux
FROM postgres:17.2-alpine

# Copy all SQL initialization scripts from the local initdb directory to the container's initialization directory
COPY initdb/*.sql /docker-entrypoint-initdb.d/
