#! /bin/bash

__BASE_DN="${LDAP_BASE_DN}"
__LDAP_BACKEND=${LDAP_BACKEND:-mdb}
__READONLY_USER=${LDAP_READONLY_USER_USERNAME:-readonly}
__SSP_USERNAME="${LDAPEXT__SSP_USER_USERNAME}"
__SSP_PASSWORD="${LDAPEXT__SSP_USER_PASSWORD}"

__CURR_DIR="$(dirname `realpath $0`)"
source "${__CURR_DIR}/../libs/func.sh"

generate_ldif_service_ssp() {
    cat <<EOF
dn: uid=${__SSP_USERNAME},ou=services,${__BASE_DN}
changetype: add
objectClass: top
objectClass: account
objectClass: simpleSecurityObject
uid: ssp
description: Self Service Password User
memberOf: cn=services,ou=groups,${__BASE_DN}
userPassword: ${__SSP_PASSWORD}
EOF
}
generate_ldif_access_ssp() {
    if ! is_dn_existing_mute "cn=${__READONLY_USER},${__BASE_DN}"; then
        cat <<EOF
dn: olcDatabase={1}${__LDAP_BACKEND},cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to *
  by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage
  by * break
olcAccess: {1}to dn.subtree="ou=people,${__BASE_DN}" attrs=info,userPassword,shadowLastChange
  by self write
  by dn="cn=admin,${__BASE_DN}" write
  by dn="uid=${__SSP_USERNAME},ou=services,${__BASE_DN}" write
  by anonymous auth
  by * break
olcAccess: {2}to attrs=info,userPassword,shadowLastChange
  by self write
  by dn="cn=admin,${__BASE_DN}" write
  by anonymous auth
  by * none
olcAccess: {2}to *
  by self read
  by dn="cn=admin,${__BASE_DN}" write
  by dn="uid=${__SSP_USERNAME},ou=services,${__BASE_DN}" read
  by * none
EOF
    else
        cat <<EOF
dn: olcDatabase={1}${__LDAP_BACKEND},cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to *
  by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage
  by * break
olcAccess: {1}to dn.subtree="ou=people,${__BASE_DN}" attrs=info,userPassword,shadowLastChange
  by self write
  by dn="cn=admin,${__BASE_DN}" write
  by dn="cn=${__READONLY_USER},${__BASE_DN}" read
  by dn="uid=${__SSP_USERNAME},ou=services,${__BASE_DN}" write
  by anonymous auth
  by * break
olcAccess: {2}to attrs=info,userPassword,shadowLastChange
  by self write
  by dn="cn=admin,${__BASE_DN}" write
  by dn="cn=${__READONLY_USER},${__BASE_DN}" read
  by anonymous auth
  by * none
olcAccess: {3}to *
  by self read
  by dn="cn=admin,${__BASE_DN}" write
  by dn="cn=${__READONLY_USER},${__BASE_DN}" read
  by dn="uid=${__SSP_USERNAME},ou=services,${__BASE_DN}" read
  by * none
EOF
    fi
}

configurate() {
    if ! is_dn_existing_mute "uid=${__SSP_USERNAME},ou=services,${__BASE_DN}"; then
        log_print INFO "Try to add ssp user: uid=${__SSP_USERNAME},ou=services,${__BASE_DN}"
        import_ldif_data "$(generate_ldif_service_ssp)" \
            && log_print INFO "Success to add ssp user: 'uid=${__SSP_USERNAME},ou=services,${__BASE_DN}'." \
            || ( \
                log_print ERROR "FAILED to add ssp user: 'uid=${__SSP_USERNAME},ou=services,${__BASE_DN}'." >&2
                return 1
            )
        import_ldif_data "$(generate_ldif_access_ssp)" \
            && log_print INFO "Success to update olcAccess for ssp user." \
            || (log_print ERROR "FAILED to update olcAccess for ssp user." >&2; return 1)
    fi
}

main() {
    if [[ -n "${__SSP_USERNAME}" && -n "${__SSP_PASSWORD}" ]]; then
        configurate
    fi
    local ret=$?
    return $ret
}

main
exit $?
