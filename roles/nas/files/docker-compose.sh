#! /bin/bash

ENV_FILE_DEFAULT="datapoints.env"
COMPOSE_ARGS=()

for COMPOSE_FILE in $(ls -1 docker-compose.*.yml)
do
    COMPOSE_ARGS+=("-f" "$COMPOSE_FILE")
done

if [ -f "${ENV_FILE_DEFAULT}" ]; then
    COMPOSE_ARGS+=("--env-file" "${ENV_FILE_DEFAULT}")
fi

set -x
exec docker-compose ${COMPOSE_ARGS[@]} $@
