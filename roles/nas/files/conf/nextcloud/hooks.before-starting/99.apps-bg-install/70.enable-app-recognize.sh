#!/usr/bin/env bash

cd /var/www/html/

php occ app:enable recognize

if [[ ! -d custom_apps/recognize/models ]]; then
    # Download the models
    echo ">>> Downloading the models for recognize app."
    php occ recognize:download-models
    echo ">>> Done, return code: <$?>"
fi

php occ config:app:set recognize enabled --value="true"
php occ config:app:set recognize landmarks.enabled --value="true"
php occ config:app:set recognize faces.enabled --value="true"
php occ config:app:set recognize musicnn.enabled --value="true"

# php occ config:app:set recognize imagenet.enabled --value="true"
# php occ config:app:set movinet.enabled --value="true"
