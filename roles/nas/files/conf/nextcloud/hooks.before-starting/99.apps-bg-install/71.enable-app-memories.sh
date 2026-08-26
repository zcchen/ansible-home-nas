#!/usr/bin/env bash

cd /var/www/html/

php occ app:enable memories

if [[ -z "$(cat config/config.php | grep 'memories.gis_type')" ]]; then
    # set up reverse geocoding, will force re-indexing
    echo ">>> Downloading reverse geocoding data."
    php occ memories:places-setup
    echo ">>> Done, return code: <$?>"
fi

# echo ">>> Change the <https://tile.openstreetmap.org> to <https://server.arcgisonline.com>."
# set -x
# sed -i 's|https://tile.openstreetmap.org/{z}/{x}/{y}.png|https://server.arcgisonline.com/arcgis/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}.png|g' custom_apps/memories/js/memories-components_top-matter_MapSplitMatter_vue.js
# sed -i 's|https://tile.openstreetmap.org/{z}/{x}/{y}.png|https://server.arcgisonline.com/arcgis/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}.png|g' custom_apps/memories/js/memories-components_top-matter_MapSplitMatter_vue.js.map
# sed -i 's|https://tile.openstreetmap.org|https://server.arcgisonline.com|g' custom_apps/memories/lib/Controller/PageController.php
# set +x
# echo ">>> Changed ...."
