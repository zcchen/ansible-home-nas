#!/usr/bin/env bash

cd /var/www/html/

php occ config:app:set files_pdfviewer enable_scripting --value=yes
