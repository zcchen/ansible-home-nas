#!/usr/bin/env bash

cd /var/www/html/

if [ "${NC_CONFIGS__USE_EMAIL:-false}" = "true" ]; then
    # set SMTP server
    php occ config:system:set mail_smtpmode --value="smtp"
    php occ config:system:set mail_smtphost --value="${MAIL_SMTP_HOST}"
    php occ config:system:set mail_smtpport --value="${MAIL_SMTP_PORT}"
    php occ config:system:set mail_smtpsecure --value="${MAIL_SMTP_SECURE}"
    # set SMTP auth
    if [ "${MAIL_SMTP_AUTH:-false}" = "true" ]; then
        php occ config:system:set mail_smtpauth --value="true"
    fi
    php occ config:system:set mail_smtpname --value="${MAIL_SMTP_USER}"
    echo "System config value mail_smtppassword set to string ***************"
    php occ config:system:set mail_smtppassword --value="${MAIL_SMTP_PASS}" > /dev/null
    # set sender name
    php occ config:system:set mail_from_address --value="${MAIL_NAME_FROMID:-noreply}"
    php occ config:system:set mail_domain --value="${MAIL_NAME_DOMAIN:-example.com}"
    php occ config:system:set mail_from_name --value="Nextcloud Notification"
    # set admin mailbox
    php occ user:setting ${NEXTCLOUD_ADMIN_USER} settings email "${MAIL_NAME_FROMID:-noreply}@${MAIL_NAME_DOMAIN:-example.com}"
fi
