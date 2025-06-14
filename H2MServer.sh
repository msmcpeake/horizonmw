#!/usr/bin/bash

# Ensure H2M directory exists
if [ ! -d "H2M" ]; then
  echo "Directory 'H2M' does not exist."
  exit 1
fi

# Change into the H2M directory
chmod -R 777 H2M
cd H2M || exit 1

# Run the server with Wine
wineserver -w
env
wine hmw-mod.exe -nosteam -dedicated -memoryfix +exec server.cfg +set net_ip 0.0.0.0 +set net_port "$SERVER_PORT" +map_rotate
