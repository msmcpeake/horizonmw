#!/bin/bash
# H2M Base Installation Script
#
# Server Files: /mnt/server
# Image to install with is 'ghcr.io/parkervcp/yolks:wine_staging'

# Install packages. Default packages below are not required if using our existing install image thus speeding up the install process.
apt -y update
apt -y --no-install-recommends install curl lib32gcc-s1 ca-certificates unzip jq coreutils wget sudo

# Launch Xvfb
echo "[INFO] Starting Xvfb on DISPLAY=:0 (${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x${DISPLAY_DEPTH})"
#mkdir -p /tmp/.X11-unix
#chmod 1777 /tmp/.X11-unix
Xvfb :0 -screen 0 ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x${DISPLAY_DEPTH} &
export DISPLAY=:0

## just in case someone removed the defaults.
if [[ "${STEAM_USER}" == "" ]] || [[ "${STEAM_PASS}" == "" ]]; then
    echo -e "steam user is not set.\n"
    echo -e "Using anonymous user.\n"
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
else
    echo -e "user set to ${STEAM_USER}"
fi

## download and install steamcmd
cd /tmp
mkdir -p /mnt/server/steamcmd
chown -R root:root /mnt
chown -R root:root /mnt/server

cd /mnt/server/steamcmd
curl curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# SteamCMD fails otherwise for some reason, even running as root.
# This is changed at the end of the install process anyways.
chown -R root:root /mnt
chown -R root:root /mnt/server
chown -R root:root /home/container
export HOME=/mnt/server

## Create new server directory
mkdir -p /mnt/server/H2M
cd /mnt/server

## Install game using steamcmd.sh
steamcmd/steamcmd.sh +@sSteamCmdForcePlatformType windows +force_install_dir /mnt/server/H2M +login ${STEAM_USER} ${STEAM_PASS} +app_update ${SRCDS_APPID} validate +quit

# Winetricks
cd /mnt/server
WINEPREFIX=/mnt/server/.wine
WINEDEBUG=-all
echo "[INFO] Installing Steam through winetricks"
winetricks --unattended --force --no-isolate -q steam
wineserver -w
echo "[INFO] Starting Steam once to update"
wine "$WINEPREFIX/drive_c/Program Files (x86)/Steam/Steam.exe" -silent &
echo "[INFO] Sleeping to wait for Steam to finish"
sleep 180  # Give Steam time to settle
pkill -f Steam.exe
wineserver -w
wine reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v Steam /f
chown -R root:root /mnt
chown -R root:root /mnt/server
chown -R root:root /home/container

# Install H2M mod files
cd /mnt/server/H2M
curl -sSL -o updater.sh https://raw.githubusercontent.com/msmcpeake/horizonmw/refs/heads/main/updater.sh
chmod +x updater.sh
./updater.sh

curl -sSL -o server.cfg https://raw.githubusercontent.com/msmcpeake/horizonmw/refs/heads/main/horizon-mw-call-of-duty-modern-warfare-2-multiplayer-resmasteredserver.cfg

cd /mnt/server
curl -sSL -o H2MServer.sh https://raw.githubusercontent.com/msmcpeake/horizonmw/refs/heads/main/H2MServer.sh
chmod +x H2MServer.sh

chmod -R 777 /mnt/server/H2M

## install end
echo "-----------------------------------------"
echo "Installation completed..."
echo "-----------------------------------------"
