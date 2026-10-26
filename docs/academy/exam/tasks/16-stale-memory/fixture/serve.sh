#!/bin/sh
# serve.sh: start the shop service with the settings in config/server.conf
cd "$(dirname "$0")" || exit 1
port=$(awk -F' *= *' '$1 == "port" {print $2}' config/server.conf)
workers=$(awk -F' *= *' '$1 == "workers" {print $2}' config/server.conf)
exec ./shopd --listen "0.0.0.0:$port" --workers "$workers"
