#! /bin/bash

__BASE_DN="${LDAP_BASE_DN}"

__CURR_DIR="$(dirname `realpath $0`)"
source "${__CURR_DIR}/../libs/func.sh"

generate_ldif_ou_people() {
    cat <<EOF
dn: ou=people,${__BASE_DN}
changetype: add
ou: people
objectClass: organizationalUnit
EOF
}
generate_ldif_ou_services() {
    cat <<EOF
dn: ou=services,${__BASE_DN}
changetype: add
ou: services
objectClass: organizationalUnit
EOF
}
generate_ldif_ou_groups() {
    cat <<EOF
dn: ou=groups,${__BASE_DN}
changetype: add
ou: groups
objectClass: organizationalUnit
EOF
}
generate_ldif_group_people() {
    cat <<EOF
dn: cn=people,ou=groups,${__BASE_DN}
changetype: add
objectClass: top
objectClass: groupOfMembers
cn: People
description: Group for human users
EOF
}
generate_ldif_group_services() {
    cat <<EOF
dn: cn=services,ou=groups,${__BASE_DN}
changetype: add
objectClass: top
objectClass: groupOfMembers
cn: Services
description: Group for service users
EOF
}

configurate() {
    if ! is_dn_existing_mute "ou=people,${__BASE_DN}"; then
        log_print INFO "try to add: ou=people"
        import_ldif_data "$(generate_ldif_ou_people)" \
            && log_print INFO "Success to Add: ou=people" \
            || (log_print ERROR "FAILED to Add: ou=people" >&2; return 1)
    fi
    if ! is_dn_existing_mute "ou=services,${__BASE_DN}"; then
        log_print INFO "try to add: ou=services"
        import_ldif_data "$(generate_ldif_ou_services)" \
            && log_print INFO "Success to Add: ou=services" \
            || (log_print ERROR "FAILED to Add: ou=services" >&2; return 1)
    fi
    if ! is_dn_existing_mute "ou=groups,${__BASE_DN}"; then
        log_print INFO "try to add: ou=groups"
        import_ldif_data "$(generate_ldif_ou_groups)" \
            && log_print INFO "Success to Add: ou=groups" \
            || (log_print ERROR "FAILED to Add: ou=groups" >&2; return 1)
    fi
    if ! is_dn_existing_mute "cn=people,ou=groups,${__BASE_DN}"; then
        log_print INFO "try to add: cn=people,ou=groups"
        import_ldif_data "$(generate_ldif_group_people)" \
            && log_print INFO "Success to Add: cn=people,ou=groups" \
            || (log_print ERROR "FAILED to Add: cn=people,ou=groups" >&2; return 1)
    fi
    if ! is_dn_existing_mute "cn=services,ou=groups,${__BASE_DN}"; then
        log_print INFO "try to add: cn=services,ou=groups"
        import_ldif_data "$(generate_ldif_group_services)" \
            && log_print INFO "Success to Add: cn=services,ou=groups" \
            || (log_print ERROR "FAILED to Add: cn=services,ou=groups" >&2; return 1)
    fi
    return 0
}

main() {
    configurate
    local ret=$?
    return $ret
}

main
exit $?
