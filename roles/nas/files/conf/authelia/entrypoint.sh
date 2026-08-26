#! /bin/sh

if [ ! -f "/config/private.pem" ]; then
    /app/authelia crypto pair rsa generate --directory /config/ --file.private-key private.pem
fi

exec /app/entrypoint.sh $@
