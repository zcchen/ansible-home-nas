#!  /bin/sh

set -e

if [ "$DEBUG" = "true" ]; then
    set -x
fi

################################################################################
# Functions
################################################################################

cleanup() {
    echo "Shutdown requested, exiting gracefully..."
    exit 0
}

debug_print() {
    if [ "$DEBUG" = "true" ]; then
        echo "$1"
    fi
}

configure_uid_and_gid() {
    debug_print "Preparing environment for $PUID:$PGID..."
    chown -R "${PUID}:${PGID}" \
        /etc/letsencrypt \
        /var/lib/letsencrypt \
        /var/log/letsencrypt \
        /opt/certbot
}

certbot_cmd="su-exec ${PUID:-0}:${PGID:-0} certbot"

run_certbot() {
    # Ensure the log directory is set to 700
    chmod 700 /var/log/letsencrypt
    chown "${PUID:-0}:${PGID:-0}" /var/log/letsencrypt

    debug_print "Running certbot with command: $certbot_cmd"

    # Add -v flag if DEBUG is enabled
    local debug_flag=""
    if [ "$DEBUG" = "true" ]; then
        debug_flag="-v"
    fi
    local email_args=""
    if [ -n "$CERTBOT_EMAIL" ]; then
        email_args="--email $CERTBOT_EMAIL"
    fi
    local deploy_args=""
    if [ -n "$RENEWAL_DEPLOY_HOOK" ]; then
        deploy_args="--deploy-hook '$RENEWAL_DEPLOY_HOOK'"
    fi

    # Build additional certbot flags using positional parameters
    set --  # Reset positional parameters
    # append the domain list
    OLD_IFS="$IFS"; IFS=","
    for dom in $CERTBOT_DOMAINS; do
        cleaned_dom=$(echo "$dom" | tr -d '[:space:]')
        [ -n "$cleaned_dom" ] && set -- "$@" -d "$cleaned_dom"
    done
    IFS="$OLD_IFS"
    if [ -n "$CERTBOT_CERT_NAME" ]; then
        set -- "$@" --cert-name "$CERTBOT_CERT_NAME"
    fi
    if [ "$CERTBOT_EXPAND" = "true" ]; then
        set -- "$@" --expand
    fi
    if [ -n "$CERTBOT_EMAIL" ]; then
        set -- "$@" --email "$CERTBOT_EMAIL"
    fi
    if [ -n "$RENEWAL_DEPLOY_HOOK" ]; then
        set -- "$@" --deploy-hook "$RENEWAL_DEPLOY_HOOK"
    fi
    if [ "$STAGING" = "true" ]; then
        set -- "$@" --staging
    fi

    $certbot_cmd $debug_flag certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials "$CLOUDFLARE_CREDENTIALS_FILE" \
        --dns-cloudflare-propagation-seconds "$CLOUDFLARE_PROPAGATION_SECONDS" \
        --key-type "$CERTBOT_KEY_TYPE" \
        --server "$CERTBOT_SERVER" \
        --agree-tos \
        --non-interactive \
        --strict-permissions \
        "$@"
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "Error: certbot command failed with exit code $exit_code"
        exit 1
    fi
}

wait_renew() {
    while true; do
        # POSIX-compliant way to show next run time
        local current_timestamp=$(date +%s)
        local next_timestamp=$((current_timestamp + RENEWAL_INTERVAL))
        local next_run=$(date -r "$next_timestamp" '+%Y-%m-%d %H:%M:%S %z' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S %z')
        echo "Next certificate renewal check will be at ${next_run}"

        # use `wait` to catch the TERM signal
        sleep "$RENEWAL_INTERVAL" &
        local sleep_pid=$!
        wait $sleep_pid
        local sleep_ret=$?

        # Check if we received a signal (more portable check)
        case $sleep_ret in
            0) : ;; # Normal exit
            *) cleanup ;;   # terminated to exit
        esac

        $certbot_cmd renew
        local certbot_ret=$?
        if [ $certbot_ret -ne 0 ]; then
            echo "Error: Certificate renewal failed. Exiting."
            exit 1
        fi
    done
}

validate_environment_variables() {
    # Validate required environment variables
    for var in CLOUDFLARE_API_TOKEN CERTBOT_DOMAINS CERTBOT_KEY_TYPE CERTBOT_SERVER CLOUDFLARE_CREDENTIALS_FILE CLOUDFLARE_PROPAGATION_SECONDS; do
        if [ -z "$(eval echo \$$var)" ]; then
            echo "Error: $var environment variable is not set"
            exit 1
        fi
    done
}

vars_print() {
    cat <<"EOF"
< Certbot, activate! >
 --------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
EOF
    echo "🚀 Let's Get Encrypted! 🚀"
    echo "🌐 Domain(s): $CERTBOT_DOMAINS"
    echo "📧 Email: $CERTBOT_EMAIL"
    echo "🌐 Certbot Server: $CERTBOT_SERVER"
    echo "🔑 Key Type: $CERTBOT_KEY_TYPE"
    echo "⏰ Renewal Interval: $RENEWAL_INTERVAL seconds"
    echo "🕒 DNS Propagation Wait: $CLOUDFLARE_PROPAGATION_SECONDS seconds"
    echo "Let's Encrypt, shall we?"
    echo "-----------------------------------------------------------"


}

# main func
main() {
    trap cleanup TERM INT
    if [ "$DEBUG" = "true" ]; then
        echo "show trapped signals and their corresponding action:"
        trap
        echo "----------------------------------------------------"
    fi

    # Check if a command was passed to the container
    if [ $# -gt 0 ]; then
        exec su-exec "${PUID:-0}:${PGID:-0}" "$@"
    else
        validate_environment_variables
        vars_print
        configure_uid_and_gid

        # Create Cloudflare configuration file
        echo "dns_cloudflare_api_token = $CLOUDFLARE_API_TOKEN" > "$CLOUDFLARE_CREDENTIALS_FILE"
        chmod 600 "$CLOUDFLARE_CREDENTIALS_FILE"
        chown "${PUID:-0}:${PGID:-0}" "$CLOUDFLARE_CREDENTIALS_FILE"

        # Run certbot initially to get the certificates
        run_certbot
        # If RENEWAL_INTERVAL is set to 0, do not attempt to renew certificates and exit immediately
        if [ "$RENEWAL_INTERVAL" = "0" ]; then
            echo "Let's Encrypt Renewals are disabled because RENEWAL_INTERVAL=0. Running once and exiting..."
            cleanup
        else
            wait_renew
        fi
    fi
}

main $@
