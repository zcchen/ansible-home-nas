#! /bin/bash

if [ -n "${LDAPEXT__SSP_USER_USERNAME}" ]; then
    __LDAP_USERNAME="uid=${LDAPEXT__SSP_USER_USERNAME},ou=services,$LDAP_BASE_DN"
    __LDAP_PASSWORD="${LDAPEXT__SSP_USER_PASSWORD}"
else
    __LDAP_USERNAME="cn=admin,$LDAP_BASE_DN"
    __LDAP_PASSWORD="${LDAP_ADMIN_PASSWORD}"
fi

gen_ssp_config__base() {
    cat >/var/www/conf/config.inc.local.php <<EOF
<?php
# Debug mode
\$debug = false;

# LDAP
\$ldap_url = "ldap://ldap";
\$ldap_starttls = false;
\$ldap_binddn = '${__LDAP_USERNAME}';
\$ldap_bindpw = '${__LDAP_PASSWORD}';
\$ldap_base = "$LDAP_BASE_DN";
\$ldap_login_attribute = "uid";
\$ldap_fullname_attribute = "cn";
\$ldap_filter = "(&(\$ldap_login_attribute={login})(objectClass=person)(memberOf=cn=people,ou=groups,$LDAP_BASE_DN))";
# Who changes the password (and save question/answer as well)? user: the user itself; manager: the above binddn
\$who_change_password = "user";

# Domain settings
\$reset_url = "https://ssp.${DOMAIN_BASE:-example.com}/";

# Question
\$use_questions = ${USE_QUESTIONS:-false};

# SMS
\$use_sms = ${USE_SMS:-false};

EOF

    if [[ "${USE_EMAIL}" = "true" ]]; then
        cat >> /var/www/conf/config.inc.local.php <<EOF
# EMAIL
\$use_tokens = ${USE_EMAIL:-false};
\$keyphrase = "${LDAPSSP__SECRETS_KEYPHRASE:-secret}";
\$mail_from = "${MAIL_NAME_FROMID:-admin}@${MAIL_NAME_DOMAIN:-example.com}";
\$mail_smtp_auth = ${MAIL_SMTP_AUTH:-false};
\$mail_smtp_host = '${MAIL_SMTP_HOST:-localhost}';
\$mail_smtp_port = ${MAIL_SMTP_PORT:-25};
\$mail_smtp_secure = '${MAIL_SMTP_SECURE:-tls}';
\$mail_smtp_user = '$MAIL_SMTP_USER';
\$mail_smtp_pass = '$MAIL_SMTP_PASS';
\$mail_smtp_timeout = 30;
\$mail_smtp_keepalive = false;
\$mail_address_use_ldap = true;
EOF
    else
        cat >> /var/www/conf/config.inc.local.php <<EOF
# EMAIL
\$use_tokens = false;
EOF
    fi

    cat >> /var/www/conf/config.inc.local.php <<EOF
?>
EOF
}

gen_ssp_config__base
exec /entrypoint.sh $@
