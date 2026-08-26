#!/usr/bin/env bash

cat <<EOF > /var/www/html/config/base.config.php
<?php
\$CONFIG = [
    // domain related config
    'lost_password_link' => 'https://ssp.${DOMAIN_BASE}',
    'trusted_domains' => [
      'files',
      'files.${DOMAIN_BASE}',
    ],

    // background-job timing
    'maintenance_window_start' => ${NC_CONFIGS__MAINTENACE_WINDOW_START},

    // locale config
    'default_locale' => '${NC_CONFIGS__DEFAULT_LOCALE}',
    'default_phone_region' => '${NC_CONFIGS__DEFAULT_LOCALE}',

    // app config
    'defaultapp' => '${NC_CONFIGS__DEFAULT_APP}',

    // local oidc solution requied
    'allow_local_remote_servers' => true,

    // reversed proxy
    'trusted_proxies' => explode(' ', getenv('TRUSTED_PROXIES')),

    // imaginary preview
    'enable_previews' => true,
    'enabledPreviewProviders' => [
        "OC\\Preview\\MP3",
        "OC\\Preview\\TXT",
        "OC\\Preview\\MarkDown",
        "OC\\Preview\\OpenDocument",
        "OC\\Preview\\Krita",
        "OC\\Preview\\Imaginary",
        "OC\\Preview\\ImaginaryPDF",
        "OC\\Preview\\Image",
        "OC\\Preview\\Movie",
        "OC\\Preview\\HEIC",
        "OC\\Preview\\TIFF"
    ],
    'preview_imaginary_url' => 'http://imaginary.nextcloud',
    'preview_max_x' => 1024,
    'preview_max_y' => 1024,
    'preview_max_scale_factor' => 1,

    'allowed_admin_ranges' => [
      '127.0.0.1/8',
      '192.168.0.0/16',
      '172.16.0.0/12',
      'fd00::/8',
    ],

];
?>
EOF

if [[ -n "${http_proxy}" || -n "${https_proxy}" ]]; then
cat <<EOF >> /var/www/html/config/proxy.config.php
<?php
\$CONFIG = [
    // network proxy
    'proxy' => '${https_proxy}',
    'proxyuserpwd' => '${NC_CONFIGS__PROXY_USER_PASSED}',
    'proxyexclude' => explode(',', getenv('no_proxy')),
];
?>
EOF
fi

