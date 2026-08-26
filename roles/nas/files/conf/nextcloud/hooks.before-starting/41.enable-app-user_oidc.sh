#!/usr/bin/env bash

cd /var/www/html/

echo ">>> Enable Plugin <user_oidc>."
php occ app:enable user_oidc
echo ">>> Configuarting Plugin <user_oidc>."
php occ user_oidc:provider "${DOMAIN_BASE}" \
    --clientid="${NC_SECRET__AUTHELIA_CLIENT_ID}" \
    --clientsecret="${NC_SECRET__AUTHELIA_CLIENT_SECRET}" \
    --discoveryuri="https://auth.${DOMAIN_BASE}/.well-known/openid-configuration" \
    --scope="openid email profile groups" \
    --mapping-uid="preferred_username" \
    --group-provisioning=1 --unique-uid=0
echo ">>> Plugin <user_oidc> is ready, and configurated."
# php occ config:app:set --value=1 user_oidc allow_multiple_user_backends
