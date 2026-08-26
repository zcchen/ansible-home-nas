#! /bin/bash

__OPENLDAP_USER="openldap"
__OPENLDAP_GROUP="openldap"
__SLAPD_START_DONE="${CONTAINER_STATE_DIR}/slapd-first-start-done"

__CURR_DIR="$(dirname `realpath $0`)"
source "${__CURR_DIR}/libs/func.sh"


service_init_wait() {
    log_print INFO "Wait OpenLDAP service init finishing..."
    while [ ! -e "$__SLAPD_START_DONE" ]; do sleep 0.1; done
    log_print INFO ">>>> OpenLDAP service init finishing..."
}

service_start() {
    log_print INFO "Starting OpenLDAP proc by script <$0>..."
    ulimit -n ${LDAP_NOFILE:-1024}  # NOTE: main point, without it, slapd will raise core-dump error.
    /usr/sbin/slapd -h "ldap://127.0.0.1:389 ldapi:///" -u ${__OPENLDAP_USER} -g ${__OPENLDAP_GROUP} -d 512 &
    while [ ! -e /run/slapd/slapd.pid ]; do sleep 0.1; done
    log_print DEBUG "OpenLDAP proc (pid: $(cat /run/slapd/slapd.pid)) is running by script <$0>..."
}
service_stop() {
    log_print INFO "Stopping the OpenLDAP proc managed by script <$0>..."
    local slapd_pid=$(cat /run/slapd/slapd.pid)
    log_print DEBUG "Terminating OpenLDAP proc managed by script <$0>, pid: ${slapd_pid}."
    kill -15 $slapd_pid
    while [ -e /proc/$slapd_pid ]; do sleep 0.1; done
    log_print INFO "OpenLDAP proc by script <$0> is STOPPED."
}

main() {
    local r=0
    service_init_wait
    service_start
    for s in $(ls -1 ${__CURR_DIR}/scripts/*.sh); do
        $s
        local ret=$?
        if [ $ret -ne 0 ]; then
            r=$ret
            log_print ERROR "FAILED to execute script: <$0>, exit code: <$ret>."
            break
        fi
    done
    service_stop
    return $r
}

main
exit $?
