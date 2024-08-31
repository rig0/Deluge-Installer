#!/bin/bash
# RAMBO TORRENT BOX SETUP SCRIPT. [DEBIAN 9+]
# Installs Deluge Daemon and Web-UI

usr=$1 # username to add to deluge group (optional argument)
delugeUsr="debian-deluged" # the user the deluge pkg creates and uses

# Bash styling
BLUE='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # no color
ST="\n${YELLOW}----------------------------------------------------------------------\n\n"
SB="\n----------------------------------------------------------------------\n\n${NC}"
delay=1 # delay in seconds after showing step

printf "$ST Updating OS & Installing Deluge \n $SB"
sleep $delay
apt update && apt dist-upgrade -y
apt install deluged deluge-web -y

printf "$ST Configuring Deluge \n $SB"
sleep $delay

# Check if media group exists
if getent group "media" > /dev/null 2>&1; then
    echo "Group 'media' already exists. Skipping step"
else
    groupadd media
fi

# Add deluge user to media group
usermod -aG media $delugeUsr

# Add user to deluge and media group
if [ $# -ge 1 ]; then 
    usermod -aG media $usr
    usermod -aG $delugeUsr $usr
fi

# Creating download folders & setting permssions that play nice with servarr stack
if [ ! -d "/mnt/deluge" ]; then
    mkdir /mnt/deluge    
fi
chmod 774 /mnt/deluge
chown -R $delugeUsr:media /mnt/deluge

sleep $delay
systemctl stop deluged
systemctl stop deluge-web

printf "$ST Editing service to to download fils with correct permissions \n $SB"
sleep $delay
# Edit the init.d script
sed -i '/^MASK=/s/0027/0002/' "/etc/init.d/deluged" 
sed -i '/^USER=/a GROUP=media' "/etc/init.d/deluged"

# Edit the daemon service
$daemonService = '/lib/systemd/system/deluged.service'
if [ -f $daemonService ]; then
    sed -i '/^UMask=/s/007/002/' $daemonService
    sed -i '/^Group=/s/debian-deluged/media/' $daemonService 
fi
# Edit the web service
$webService = '/lib/systemd/system/deluge-web.service'
if [ -f $webService ]; then
    sed -i '/^UMask=/s/007/002/' $webService
    sed -i '/^Group=/s/debian-deluged/media/' $webService
fi

# reload the system services daemon
systemctl daemon-reload

printf "$ST Changing default download location \n $SB"
sleep $delay
# Change the default download location
sed -i 's#"download_location": "/var/lib/deluged/Downloads"#"download_location": "/mnt/deluge"#' "/var/lib/deluged/config/core.conf"
sed -i 's#"move_completed_path": "/var/lib/deluged/Downloads"#"move_completed_path": "/mnt/deluge"#' "/var/lib/deluged/config/core.conf"
sed -i 's#"torrentfiles_location": "/var/lib/deluged/Downloads"#"torrentfiles_location": "/mnt/deluge"#' "/var/lib/deluged/config/core.conf"

printf "$ST Starting daemon service \n $SB"
sleep $delay

# Starting daemon service
systemctl start deluged
systemctl status deluged --no-pager

printf "$ST Starting web service \n $SB"
sleep $delay
# Starting web service
systemctl start deluge-web
systemctl status deluge-web --no-pager

# Check if UFW is installed
if command -v ufw > /dev/null 2>&1; then
    # Check if UFW is enabled
    if sudo ufw status | grep -q "Status: active"; then
        ufw allow 8112/tcp
    fi
fi

# Sending notification is pushover is installed
if [ -f /usr/bin/pushover ]; then
    pushover "Deluge Setup Complete"
fi

printf "\n${BLUE}----------------------------------------------------------------------\n\n"
printf "Setup Complete! \n$SB"