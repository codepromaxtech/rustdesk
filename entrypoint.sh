#!/bin/bash

# Start RustDesk hbbs
/usr/local/bin/hbbs -k /etc/rustdesk/id_ed25519 &

# Start RustDesk hbbr
/usr/local/bin/hbbr -k /etc/rustdesk/id_ed25519 &

# Start NGINX
nginx -g 'daemon off;'
