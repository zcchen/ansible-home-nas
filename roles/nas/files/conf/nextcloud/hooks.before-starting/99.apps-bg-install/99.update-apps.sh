#!/usr/bin/env bash

cd /var/www/html/

echo ">>> Updating the current apps."
php occ app:update --all
echo ">>> All apps are updated."

