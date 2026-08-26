#!/usr/bin/env bash

cd /var/www/html/

php occ config:system:set --type boolean --value false auth.webauthn.enabled
