# Deluge-Installer

Deluge install script for headless debian based linux servers.
Installs deluge daemon and deluge web interface.

**Needs to be run as root**

## Install

``wget -q https://rigslab.com/Rambo/Deluge-Installer/raw/branch/main/install.sh -O install.sh && chmod +x script.sh && ./script.sh``


*The script accepts an optional user argument. It adds your user to the deluge group so you can manage the downloads.*

## Post Installation

Access your web ui http://server_ip:8112

Default password for the web ui is ``deluge``

The default downloads folder is ``/mnt/deluge``

The group ``media`` has been given access to the downloads folder to enable sharing with Servarr apps.