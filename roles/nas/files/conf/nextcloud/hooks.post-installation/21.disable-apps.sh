#!/usr/bin/env bash

cd /var/www/html/

for app in "${NC_CONFIGS__DISABLE_APPS[@]}"; do
    php occ app:disable ${app}
done
