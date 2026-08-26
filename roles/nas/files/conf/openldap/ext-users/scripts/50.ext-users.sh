#! /bin/bash

__CURR_DIR="$(dirname `realpath $0`)"
source "${__CURR_DIR}/../libs/func.sh"

file_env LDAPEXT__USERS_LIST

__BASE_DN="${LDAP_BASE_DN}"
__LDAP_BACKEND=${LDAP_BACKEND:-mdb}
__READONLY_USER=${LDAP_READONLY_USER_USERNAME:-readonly}
__USERS_LIST="${LDAPEXT__USERS_LIST}"
__GROUP_NAME="${LDAPEXT__USERS_GROUP}"


generate_ldif_access() {
    if ! is_dn_existing_mute "cn=${__READONLY_USER},${__BASE_DN}"; then
        cat <<EOF
dn: olcDatabase={1}${__LDAP_BACKEND},cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to *
  by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage
  by * break
olcAccess: {1}to attrs=info,userPassword,shadowLastChange
  by self write
  by dn="cn=admin,${__BASE_DN}" write
  by anonymous auth
  by * none
olcAccess: {2}to *
  by self read
  by dn="cn=admin,${__BASE_DN}" write
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
olcAccess: {1}to attrs=info,userPassword,shadowLastChange
  by self write
  by dn="cn=admin,${__BASE_DN}" write
  by anonymous auth
  by * none
olcAccess: {2}to *
  by self read
  by dn="cn=admin,${__BASE_DN}" write
  by dn="cn=${__READONLY_USER},${__BASE_DN}" read
  by * none
EOF
    fi
}
generate_ldif_user() {
    local uid="$1"
    local password="$2"
    local email="$3"
    local cn="$4"
    local sn="$5"
    test_variables_set uid password email cn sn || return 1
    cat <<EOF
dn: uid=${uid},ou=people,${__BASE_DN}
changetype: add
objectClass: top
objectClass: organizationalPerson
objectClass: inetOrgPerson
objectClass: extensibleObject
mail: ${email}
uid: ${uid}
cn: ${cn}
sn: ${sn}
userPassword: ${password}
memberOf: cn=people,ou=groups,${__BASE_DN}
EOF
}
generate_ldif_group_add() {
    local group="$1"
    local members=("${@:2}")
    test_variables_set group members || return 1
    cat <<EOF
dn: cn=${group},ou=groups,${__BASE_DN}
changetype: add
objectClass: groupOfUniqueNames
cn: ${group}
EOF
for m in ${members[@]}; do
    cat <<EOF
uniqueMember: uid=${m},ou=people,${__BASE_DN}
EOF
done
}
generate_ldif_group_append() {
    local group="$1"
    local members=("${@:2}")
    test_variables_set group members || return 1
    cat <<EOF
dn: cn=${group},ou=groups,${__BASE_DN}
changetype: modify
add: uniqueMember
EOF
for m in ${members[@]}; do
    cat <<EOF
uniqueMember: uid=${m},ou=people,${__BASE_DN}
EOF
done
}

# TODO: missing user deleting feature
configurate() {
    # Add the users from user list
    local userinfo_list=()
    local memberAdd_list=()
    local flag_skip_ldif_access=1
    IFS=";" read -r -a userinfo_list <<< "${__USERS_LIST}"
    for userinfo_raw in "${userinfo_list[@]}"; do
        local __userinfo=$(echo "$userinfo_raw" | xargs)
        local uid=$(echo "$__userinfo" | cut -d':' -f1)
        local upass=$(echo "$__userinfo" | cut -d':' -f2)
        local email=$(echo "$__userinfo" | cut -d':' -f3)
        local group=$(echo "$__userinfo" | cut -d':' -f4)
        local cn=$(echo "$__userinfo" | cut -d':' -f5 | cut -d' ' -f1)
        local sn=$(echo "$__userinfo" | cut -d':' -f5 | cut -d' ' -f2)
        if [[ -z "$uid" || -z "$upass" || -z "$email" || -z "$cn" || -z "$cn" ]]; then
            log_print ERROR "userinfo error: 'uid: <$uid>, upass: <$upass>, email: <$email>, cn: <$cn>, sn: <$sn>." >&2
        else
            if is_dn_existing_mute "uid=$uid,ou=people,${__BASE_DN}"; then
                log_print DEBUG "User 'uid=$uid,ou=people,${__BASE_DN}' already registered. Maintenance skip."
                flag_skip_ldif_access=0
            else
                memberAdd_list+=(${uid})
                log_print INFO "Try to add user 'uid=$uid,ou=people,${__BASE_DN}'."
                import_ldif_data "$(generate_ldif_user $uid $upass $email $cn $sn $group)" \
                    && log_print INFO "Success to add user 'uid=$uid,ou=people,${__BASE_DN}'." \
                    || log_print ERROR "FAILED to add user 'uid=$uid,ou=people,${__BASE_DN}'." >&2
            fi
        fi
    done
    if [[ $flag_skip_ldif_access -eq 1 ]]; then
        import_ldif_data "$(generate_ldif_access)" \
            && log_print INFO "Success to update olcAccess for common user." \
            || (log_print ERROR "FAILED to update olcAccess for common user." >&2; return 1)
    fi
    if ! is_dn_existing_mute "cn=${__GROUP_NAME},ou=groups,${__BASE_DN}"; then
        log_print INFO "Try to create group 'cn=${__GROUP_NAME},ou=groups,${__BASE_DN}'."
        import_ldif_data "$(generate_ldif_group_add ${__GROUP_NAME} ${memberAdd_list[@]})" \
            && log_print INFO "Success to create group 'cn=${__GROUP_NAME},ou=groups,${__BASE_DN}'." \
            || log_print ERROR "FAILED to create group 'cn=${__GROUP_NAME},ou=groups,${__BASE_DN}'." >&2
    else
        log_print INFO "Try to append users to group 'cn=${__GROUP_NAME},ou=groups,${__BASE_DN}'."
        import_ldif_data "$(generate_ldif_group_append ${__GROUP_NAME} ${memberAdd_list[@]})" \
            && log_print INFO "Success to append users to group 'cn=${__GROUP_NAME},ou=groups,${__BASE_DN}'." \
            || log_print ERROR "FAILED to append users to group 'cn=${__GROUP_NAME},ou=groups,${__BASE_DN}'." >&2
    fi
}

main() {
    configurate
    local ret=$?
    return $ret
}

main
exit $?
