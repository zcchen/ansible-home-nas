# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    local varValue=$(env | grep -E "^${var}=" | sed -E -e "s/^${var}=//")
    local fileVarValue=$(env | grep -E "^${fileVar}=" | sed -E -e "s/^${fileVar}=//")
    if [ -n "${varValue}" ] && [ -n "${fileVarValue}" ]; then
        log_print ERROR "ERROR: both $var and $fileVar are set (but are exclusive)"
        return 1
    fi
    if [ -n "${varValue}" ]; then
        export "$var"="${varValue}"
    elif [ -n "${fileVarValue}" ]; then
        export "$var"="$(cat "${fileVarValue}" | xargs)"
    elif [ -n "${def}" ]; then
        export "$var"="$def"
    fi
    unset "$fileVar"
}

log_print() {
    local level="$1"
    local msg="$2"
    echo "[$level]  	| $(date +"%Y-%m-%d %H:%M:%S")	| $msg"
}

test_variables_set() {
    for var in $@; do
        if [ -z "$(eval echo \$$var)" ]; then
            log_print ERROR "variable '$var' is not set" >&2
            return 1
        fi
    done
    return 0
}

is_dn_existing_mute() {
    local dn="$1"
    test_variables_set dn || return 1
    ldapsearch -Y EXTERNAL -H ldapi:/// -b "$dn" > /dev/null 2>&1
}

is_dn_existing() {
    local dn="$1"
    test_variables_set dn || return 1
    ldapsearch -Y EXTERNAL -H ldapi:/// -b "$dn"
}

is_ldap_online() {
    ldapsearch -Y EXTERNAL -H ldapi:/// -s base > /dev/null 2>&1
}

import_ldif_data() {
    local ldif_stream=$1
    echo -n "$ldif_stream" | ldapadd -Y EXTERNAL -H ldapi:///
}

