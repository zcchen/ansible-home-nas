#!/usr/bin/env bash

cd /var/www/html/

APP_LIST=(
    user_oidc  # OIDC login
    onlyoffice
    fileviewer
)


retry_exec() {
    local trying_max=$1
    shift 1
    local cmds=$@
    local trying_count=0
    while
        ${cmds}
        if [ $? -ne 0 ]; then
            trying_count=$(( ${trying_count} + 1 ))
            if [ ${trying_count} -lt ${trying_max} ]; then
                true
            else
                return 1
            fi
        else
            false
        fi
    do :; done
    return 0
}

install_app() {
    local app=$1
    echo ">>> Check Plugin <${app}> is installed?"
    if [ -z "$(php occ app:list | grep "${app}")" ]; then
        echo ">>> Try to install Plugin <${app}>."
        retry_exec 5 php occ app:install ${app}
        if [ $? -ne 0 ]; then
            echo ">>> Failed to install plugin <${app}>..."
            return 1
        else
            echo ">>> Success to install plugin <${app}>..."
        fi
    else
        echo ">>> Plugin <${app}> is installed already..."
    fi
    return 0
}

main() {
    local ret=0
    for app in ${APP_LIST[@]}; do
        install_app ${app}
        if [ $? -ne 0 ]; then
            ret=1
        fi
    done
    if [[ "${ret}" -ne 0 ]]; then
        echo ">>> FAILED to install essential apps, exiting."
        kill -SIGTERM 1
    fi
}

main
