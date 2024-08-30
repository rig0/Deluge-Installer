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
if [ $# -lt 1 ]; then
    usermod -aG media $usr
    usermod -aG $delugeUsr $usr
fi

# Creating download folders & setting permssions that play nice with servarr stack
mkdir /mnt/deluge
chmod 774 /mnt/deluge
chown -R $delugeUsr:media /mnt/deluge


printf "$ST Creating system services \n $SB"

# Creating system service for deluge
touch /etc/systemd/system/deluged.service
echo "[Unit]" >> /etc/systemd/system/deluged.service
echo "Description=Deluge Bittorrent Client Daemon" >> /etc/systemd/system/deluged.service
echo "After=network-online.target" >> /etc/systemd/system/deluged.service
echo " " >> /etc/systemd/system/deluged.service
echo "[Service]" >> /etc/systemd/system/deluged.service
echo "Type=simple" >> /etc/systemd/system/deluged.service
echo "User=$delugeUsr" >> /etc/systemd/system/deluged.service
echo "Group=$delugeUsr" >> /etc/systemd/system/deluged.service
echo "UMask=007" >> /etc/systemd/system/deluged.service
echo " " >> /etc/systemd/system/deluged.service
echo "ExecStart=/usr/bin/deluged -d" >> /etc/systemd/system/deluged.service
echo "" >> /etc/systemd/system/deluged.service
echo "Restart=on-failure" >> /etc/systemd/system/deluged.service
echo " " >> /etc/systemd/system/deluged.service
echo "# Configures the time to wait before service is stopped forcefully." >> /etc/systemd/system/deluged.service
echo "TimeoutStopSec=300" >> /etc/systemd/system/deluged.service
echo " " >> /etc/systemd/system/deluged.service
echo "[Install] " >> /etc/systemd/system/deluged.service
echo "WantedBy=multi-user.target " >> /etc/systemd/system/deluged.service

# Creating system service for deluge web interface
touch /etc/systemd/system/deluge-web.service
echo "[Unit]" >> /etc/systemd/system/deluge-web.service
echo "Description=Deluge Bittorrent Client Web Interface" >> /etc/systemd/system/deluge-web.service
echo "After=network-online.target" >> /etc/systemd/system/deluge-web.service
echo " " >> /etc/systemd/system/deluge-web.service
echo "[Service]" >> /etc/systemd/system/deluge-web.service
echo "Type=simple" >> /etc/systemd/system/deluge-web.service
echo "User=$delugeUsr" >> /etc/systemd/system/deluge-web.service
echo "Group=$delugeUsr" >> /etc/systemd/system/deluge-web.service
echo "UMask=027" >> /etc/systemd/system/deluge-web.service
echo " " >> /etc/systemd/system/deluge-web.service
echo "ExecStart=/usr/bin/deluge-web -d" >> /etc/systemd/system/deluge-web.service
echo "" >> /etc/systemd/system/deluge-web.service
echo "Restart=on-failure" >> /etc/systemd/system/deluge-web.service
echo " " >> /etc/systemd/system/deluge-web.service
echo "[Install] " >> /etc/systemd/system/deluge-web.service
echo "WantedBy=multi-user.target " >> /etc/systemd/system/deluge-web.service


printf "$ST Starting daemon service \n $SB"
# Starting daemon service
systemctl start deluged
systemctl enable deluged
systemctl status deluged --no-pager


printf "$ST Starting web service \n $SB"
# Starting web service
systemctl start deluge-web
systemctl enable deluge-web
systemctl status deluge-web --no-pager

printf "$ST Changing default download location \n $SB"
# Change the default download location

systemctl stop deluged
systemctl stop deluge-web

sed -i 's#"download_location": "/var/lib/deluged/Downloads"#"download_location": "/mnt/deluge"#' "/var/lib/deluged/.config/deluge/core.conf"
sed -i 's#"move_completed_path": "/var/lib/deluged/Downloads"#"move_completed_path": "/mnt/deluge"#' "/var/lib/deluged/.config/deluge/core.conf"
sed -i 's#"torrentfiles_location": "/var/lib/deluged/Downloads"#"torrentfiles_location": "/mnt/deluge"#' "/var/lib/deluged/.config/deluge/core.conf"

systemctl start deluged
systemctl start deluge-web

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