#!/bin/bash

for d in $(ls -1 -d /plugin-installers/*/); do
    echo ">>> try to install plugin from <$d>"
    python3 "$d/install.py" --path /var/www/onlyoffice/documentserver/sdkjs-plugins/
done

# change the permissions for the sub-dirs in `sdkjs-plugins`
for d in $(ls -1 -d /var/www/onlyoffice/documentserver/sdkjs-plugins/*/); do
    if [[ "$(basename $d)" = "markplace" || "$(basename $d)" = "v1" ]]; then
        continue
    else
        chown -R ds:ds "$d"
        chmod -R 555 "$d"
    fi
done

exec /app/ds/run-document-server.sh $@
