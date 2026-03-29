#!/bin/sh
# Inject the cluster DNS resolver into nginx config
NAMESERVER=$(grep nameserver /etc/resolv.conf | head -1 | awk '{print $2}')
export NAMESERVER=${NAMESERVER:-172.20.0.10}

# envsubst on the template (nginx alpine does this for NGINX_ENVSUBST_* vars,
# but we need NAMESERVER too)
envsubst '${BACKEND_URL} ${NAMESERVER}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'
