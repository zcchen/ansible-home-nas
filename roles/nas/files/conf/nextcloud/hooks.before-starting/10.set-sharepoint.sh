#!/usr/bin/env bash

cd /var/www/html/

php occ app:enable files_external

create_sharepoint() {
    local mount_point=$1
    local smb_host=$2
    local smb_share=$3
    local smb_user=$4
    local smb_passwd=$5
    if [ -z "$(php occ files_external:list | grep "${mount_point}")" ]; then
        echo ">>> seting up the mount point <${mount_point}>..."
        mount_id=`php occ files_external:create ${mount_point} smb password::password \
            -c host="${smb_host}" -c share="${smb_share}" \
            -c user="${smb_user}" -c password="${smb_passwd}" \
            -c root="" -c domain="" -c show_hidden=false -c case_sensitive=true -c check_acl=false -c timeout="" \
            --output=json`
        echo ">>> mount_id: <${mount_id}>."
        if [ -n "${mount_id}" ]; then
            php occ files_external:applicable --add-group "${NC_CONFIGS__GROUP_NAME}" ${mount_id}
            php occ files_external:option ${mount_id} enable_sharing true
            php occ files_external:option ${mount_id} previews true
            php occ files_external:option ${mount_id} filesystem_check_changes true
        else
            echo "--- mount point <${mount_point}> did NOT create correctly."
            return 1
        fi
    else
        echo ">>> mount point <${mount_point}> is created..."
    fi
    return 0
}

create_sharepoint "${NC_CONFIGS__SHAREPOINT_NAME}" samba.nextcloud "${SAMBA_SHARENAME}" "${SAMBA_USERNAME}" "${SAMBA_PASSWORD}"
exit $?
