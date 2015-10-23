#!/bin/bash
# Pi-hole automated install (DNS only, no local lighttpd)
# Raspberry Pi Ad-blocker
#
# Install with this command (from the Pi):
#
# wget -qO- "https://raw.githubusercontent.com/Giermann/pi-hole/master/automated%20install/dnsonly-install.sh" | bash
#  -or-
# curl -s "https://raw.githubusercontent.com/Giermann/pi-hole/master/automated%20install/dnsonly-install.sh" | bash
#
# Or run the commands below in order

# SG, 22.10.2015 - removed all lighttpd and PiFACE parts

clear
echo "  _____ _        _           _      "
echo " |  __ (_)      | |         | |     "
echo " | |__) |   __  | |__   ___ | | ___ "
echo " |  ___/ | |__| | '_ \ / _ \| |/ _ \ "
echo " | |   | |      | | | | (_) | |  __/ "
echo " |_|   |_|      |_| |_|\___/|_|\___| "
echo "                                    "
echo "      Raspberry Pi Ad-blocker       "
echo "                                    "
echo "Set a static IP before running this!"
echo "                                    "
echo "      Press Enter when ready        "
echo "                                    "
read

if [[ -f /etc/dnsmasq.d/adList.conf ]];then
        echo "Original Pi-hole detected.  Initiating sub space transport..."
        sudo mkdir -p /etc/pihole/original/
        sudo mv /etc/dnsmasq.d/adList.conf /etc/pihole/original/adList.conf.$(date "+%Y-%m-%d")
        sudo mv /etc/dnsmasq.conf /etc/pihole/original/dnsmasq.conf.$(date "+%Y-%m-%d")
        sudo mv /etc/resolv.conf /etc/pihole/original/resolv.conf.$(date "+%Y-%m-%d")
        sudo mv /usr/local/bin/gravity.sh /etc/pihole/original/gravity.sh.$(date "+%Y-%m-%d")
else
        :
fi

echo "Updating the system..."
sudo apt-get update
sudo apt-get -y upgrade

echo "Installing tools..."
sudo apt-get -y install dnsutils
sudo apt-get -y install curl

echo "Installing DNS..."
sudo apt-get -y install dnsmasq
sudo update-rc.d dnsmasq enable

echo "Stopping services to modify them..."
sudo service dnsmasq stop

echo "Backing up original config files and downloading Pi-hole ones..."
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo curl -o /etc/dnsmasq.conf "https://raw.githubusercontent.com/jacobsalmela/pi-hole/master/advanced/dnsmasq.conf"

echo "Locating the Pi-hole..."
sudo curl -o /usr/local/bin/gravity.sh "https://raw.githubusercontent.com/jacobsalmela/pi-hole/master/gravity.sh"
sudo chmod 755 /usr/local/bin/gravity.sh


# patch to add whitespace after IP
sudo sed -i "s,\$piholeIP\"'\",\$piholeIP\"' \"," /usr/local/bin/gravity.sh

# patch to work with multiple IP addresses (always redirect to 127.0.0.1) and do not change swap settings
#sudo sed -i 's,-n "$noSwap",! -n "$doSwap",' /usr/local/bin/gravity.sh
sudo sed -i "s,^\\(piholeIP=.*\\),#\\1\npiholeIP=127.0.0.1\nnoSwap=1," /usr/local/bin/gravity.sh

# patch to remove temporary files
sudo sed -i "s,\\(grep.*\$origin/\$matter > \$origin/\$andLight\\),\\1\nrm \$origin/\$matter\nrm \$latentWhitelist," /usr/local/bin/gravity.sh
sudo sed -i "s,\\(cat \$origin/\$andLight .*> \$origin/\$supernova\\),\\1\n\trm \$origin/\$andLight," /usr/local/bin/gravity.sh
sudo sed -i "s,\\(cat \$origin/\$supernova .*> \$origin/\$eventHorizon\\),\\1\n\trm \$origin/\$supernova," /usr/local/bin/gravity.sh
sudo sed -i "s,\\(cat \$origin/\$eventHorizon .*> \$origin/\$accretionDisc\\),\\1\n\trm \$origin/\$eventHorizon," /usr/local/bin/gravity.sh
sudo sed -i "s,\\(sudo cp \$origin/\$accretionDisc \$adList\\),\\1\n\trm \$origin/\$accretionDisc," /usr/local/bin/gravity.sh


# debian read-only root specific stuff
if [[ -f /sbin/init-ro ]]; then
        echo "Adding gravity.sh to run on startup..."
        sudo sed -i "/^\w*\/usr\/local\/bin\/gravity\.sh/d" /sbin/init-ro
        sudo sed -i "s,^\\(echo.*/var/tmp/resolv\.conf\\),/usr/local/bin/gravity.sh\n\\1," /sbin/init-ro

        # change gravity working directory
        sudo sed -i 's,=/etc/pihole,=/tmp/pihole,g' /etc/dnsmasq.conf
        sudo sed -i 's,=/etc/pihole,=/tmp/pihole,g' /usr/local/bin/gravity.sh
fi

echo "Entering the event horizon..."
sudo /usr/local/bin/gravity.sh

echo "Restarting services..."
#sudo shutdown -r now
sudo service dnsmasq start
