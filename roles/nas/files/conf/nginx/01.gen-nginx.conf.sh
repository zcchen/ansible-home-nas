#! /bin/bash

__DOMAIN_BASE=${DOMAIN_BASE:-example.com}

gen_nginx_conf() {
    cat > /etc/nginx/nginx.conf <<EOF
worker_processes  6;
pid /var/run/nginx.pid;
#                          [ debug | info | notice | warn | error | crit ]
error_log  /var/log/nginx.error_log  info;

events {
    worker_connections   2000;
# use [ kqueue | epoll | /dev/poll | select | poll ];
    use epoll;
}
stream {
    server {
        listen 636 ssl;
        proxy_pass ldap:389;
        ssl_certificate /etc/letsencrypt/live/${__DOMAIN_BASE}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${__DOMAIN_BASE}/privkey.pem;
    }
}
http {
    include mime.types;
    default_type  application/octet-stream;
    types {
        text/javascript mjs;
    }

    client_header_timeout  3m;
    client_body_timeout    3m;
    send_timeout           3m;

    client_header_buffer_size    1k;
    large_client_header_buffers  4 4k;

    gzip on;
    gzip_min_length  1100;
    gzip_buffers     4 8k;
    gzip_types       text/plain;

    output_buffers   1 32k;
    postpone_output  1460;

    sendfile         on;
    tcp_nopush       on;
    tcp_nodelay      on;
    # send_lowat       12000;

    # Prevent nginx HTTP Server Detection
    server_tokens   off;

    #lingering_time     30;
    #lingering_timeout  10;
    #reset_timedout_connection  on;

    server {    # skip the unsupported server names
        listen        80 default_server;
        listen        [::]:80 default_server;
        server_name   _;
        return 444;   # unknown server_name, return 444 not matched domain.
    }

    server {    # redirect to https
        listen        80;
        listen        [::]:80;
        server_name  ${__DOMAIN_BASE} *.${__DOMAIN_BASE};
        return 302 https://\$host\$uri;
    }

    server {    # serve the main server entrance
        listen        443 ssl;
        listen        [::]:443 ssl;
        listen        443 quic reuseport;
        listen        [::]:443 quic reuseport;
        http2 on;
        add_header Alt-Svc 'h3=":443"; ma=2592000,h3-29=":443"; ma=2592000';

        ssl_certificate /etc/letsencrypt/live/${__DOMAIN_BASE}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${__DOMAIN_BASE}/privkey.pem;
        server_name   ${__DOMAIN_BASE};
        # 缓存会话的有效期为 10 分钟（默认通常为5分钟，可视情况调长）
        ssl_session_timeout 10m;
        # 开启共享缓存，名为"SSL"，大小为10MB（约可缓存40,000个会话）
        ssl_session_cache shared:SSL:10m;
        ssl_buffer_size 8k;
        ssl_protocols TLSv1.3 TLSv1.2;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
        ssl_prefer_server_ciphers on;

        #index index.html index.htm;
        #root /usr/share/nginx/html/;
        return 302 https://files.${__DOMAIN_BASE};
    }

    server {    # serve the reverse proxy
        listen        443 ssl;
        listen        [::]:443 ssl;
        listen        443 quic;
        listen        [::]:443 quic;
        http2 on;
        add_header Alt-Svc 'h3=":443"; ma=2592000,h3-29=":443"; ma=2592000';

        ssl_certificate /etc/letsencrypt/live/${__DOMAIN_BASE}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${__DOMAIN_BASE}/privkey.pem;
        server_name   files.${__DOMAIN_BASE};
        # 缓存会话的有效期为 10 分钟（默认通常为5分钟，可视情况调长）
        ssl_session_timeout 10m;
        # 开启共享缓存，名为"SSL"，大小为10MB（约可缓存40,000个会话）
        ssl_session_cache shared:SSL:10m;
        ssl_buffer_size 8k;
        ssl_protocols TLSv1.3 TLSv1.2;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
        ssl_prefer_server_ciphers on;

        # The settings allows you to optimize the HTTP2 bandwidth.
        # See https://blog.cloudflare.com/delivering-http-2-upload-speed-improvements/
        # for tuning hints
        client_body_buffer_size 512k;

        set_real_ip_from 127.0.0.0/8;
        set_real_ip_from 172.16.0.0/12;
        set_real_ip_from 192.168.0.0/16;
        set_real_ip_from 10.0.0.0/8;
        # real_ip_header X-Real-IP;
        real_ip_header X-Forwarded-For;
        real_ip_recursive on;

        location / {
            resolver 127.0.0.11 valid=10s;
            proxy_cache off;
            proxy_buffering off;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-Host \$host;
            proxy_set_header X-Forwarded-For "\$http_x_forwarded_for \$realip_remote_addr";
            set \$forwarded_proto \$scheme;
            if ( \$http_x_forwarded_proto != "" ) {
                set \$forwarded_proto \$http_x_forwarded_proto;
            }
            proxy_set_header X-Forwarded-Proto \$forwarded_proto;
            proxy_pass http://files;
            proxy_http_version 2;
            # Upload big files for nextcloud
            client_max_body_size 10G;
            proxy_request_buffering off;
        }
    }

    server {    # serve the reverse proxy
        listen        443 ssl;
        listen        [::]:443 ssl;
        listen        443 quic;
        listen        [::]:443 quic;
        http2 on;
        add_header Alt-Svc 'h3=":443"; ma=2592000,h3-29=":443"; ma=2592000';
 
        ssl_certificate /etc/letsencrypt/live/${__DOMAIN_BASE}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${__DOMAIN_BASE}/privkey.pem;
        server_name   "~^(?<sub>[^\.]+)\.$(echo ${__DOMAIN_BASE} | sed -e 's#\.#\\.#g')$"
        # 缓存会话的有效期为 10 分钟（默认通常为5分钟，可视情况调长）
        ssl_session_timeout 10m;
        # 开启共享缓存，名为"SSL"，大小为10MB（约可缓存40,000个会话）
        ssl_session_cache shared:SSL:10m;
        ssl_buffer_size 8k;
        ssl_protocols TLSv1.3 TLSv1.2;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
        ssl_prefer_server_ciphers on;

        # The settings allows you to optimize the HTTP2 bandwidth.
        # See https://blog.cloudflare.com/delivering-http-2-upload-speed-improvements/
        # for tuning hints
        client_body_buffer_size 512k;

        set_real_ip_from 127.0.0.0/8;
        set_real_ip_from 172.16.0.0/12;
        set_real_ip_from 192.168.0.0/16;
        set_real_ip_from 10.0.0.0/8;
        # real_ip_header X-Real-IP;
        real_ip_header X-Forwarded-For;
        real_ip_recursive on;

        location / {
            resolver 127.0.0.11 valid=10s;
            proxy_cache off;
            proxy_buffering off;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-Host \$host;
            proxy_set_header X-Forwarded-For "\$http_x_forwarded_for \$realip_remote_addr";
            # proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            set \$forwarded_proto \$scheme;
            if ( \$http_x_forwarded_proto != "" ) {
                set \$forwarded_proto \$http_x_forwarded_proto;
            }
            proxy_set_header X-Forwarded-Proto \$forwarded_proto;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_pass http://\$sub;
            # proxy_http_version 1.1;
        }
    }
}
EOF
}

gen_nginx_conf
