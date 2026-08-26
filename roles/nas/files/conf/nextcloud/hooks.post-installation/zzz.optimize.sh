#!/usr/bin/env bash

cd /var/www/html/

php occ background:cron
php occ db:add-missing-indices
php occ config:system:set no_unsupported_browser_warning --value=true --type=boolean
php occ maintenance:repair --include-expensive

# Upload chunk size will be 20Mb
php occ config:app:set files max_chunk_size --value 20971520
