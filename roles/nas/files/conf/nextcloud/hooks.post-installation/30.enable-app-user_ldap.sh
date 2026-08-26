#!/usr/bin/env bash

cd /var/www/html/

echo ">>> Enable Plugin <user_ldap> since it is shipped directly."
php occ app:enable user_ldap

echo ">>> Configuarting Plugin <user_ldap>."
if [ -z "$(php occ ldap:show-config --output)" ]; then
    php occ ldap:create-empty-config;
fi
php occ ldap:set-config s01 ldapHost "ldap://ldap"
php occ ldap:set-config s01 ldapPort "389"
if [ ${LDAP_READONLY_USER:-false} = "true" ]; then
    php occ ldap:set-config s01 ldapAgentName "cn=${LDAP_READONLY_USER_USERNAME},${LDAP_BASE_DN}"
    php occ ldap:set-config s01 ldapAgentPassword "${LDAP_READONLY_USER_PASSWORD}"
fi
php occ ldap:set-config s01 ldapBase "${LDAP_BASE_DN}"
php occ ldap:set-config s01 ldapBaseUsers "ou=people,${LDAP_BASE_DN}"
php occ ldap:set-config s01 ldapBaseGroups "ou=groups,${LDAP_BASE_DN}"
php occ ldap:set-config s01 ldapConfigurationActive 1
php occ ldap:set-config s01 ldapLoginFilter "(&(objectclass=person)(uid=%uid))"
php occ ldap:set-config s01 ldapUserFilterObjectclass 'person'
php occ ldap:set-config s01 ldapUserFilter "(&(objectclass=person))"
php occ ldap:set-config s01 ldapGroupFilterObjectclass 'groupOfUniqueNames'
php occ ldap:set-config s01 ldapGroupFilterGroups ''
php occ ldap:set-config s01 ldapGroupFilter '(&(objectClass=groupOfUniqueNames))'
php occ ldap:set-config s01 ldapGroupMemberAssocAttr 'uniqueMember'
php occ ldap:set-config s01 ldapUserDisplayName "uid"
php occ ldap:set-config s01 ldapExpertUsernameAttr "uid"
php occ ldap:set-config s01 ldapExpertUUIDUserAttr "uid"
php occ ldap:set-config s01 ldapExpertUUIDGroupAttr "cn"
php occ ldap:set-config s01 ldapEmailAttribute "mail"

php occ ldap:test-config s01
php occ ldap:search ""
php occ group:list
echo ">>> Plugin <user_ldap> is ready, and configurated."


