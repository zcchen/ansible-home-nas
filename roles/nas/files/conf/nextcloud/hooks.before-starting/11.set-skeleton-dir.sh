#!/usr/bin/env bash

cd /var/www/html/

if [[ -n "${NC_CONFIGS__USER_SKELETON_DIR}" && -d "${NC_CONFIGS__USER_SKELETON_DIR}" ]]; then
    rm -rf "/var/www/skeleton"
    cp -rf "${NC_CONFIGS__USER_SKELETON_DIR}" "/var/www/skeleton"
    chown -R www-data:www-data "/var/www/skeleton"
    php occ config:system:set skeletondirectory --value="/var/www/skeleton"
fi
