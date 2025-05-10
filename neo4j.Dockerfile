FROM neo4j:5.11.0
LABEL maintainer="Open Network Team"

COPY .scripts/neo4j/import /var/lib/neo4j/import