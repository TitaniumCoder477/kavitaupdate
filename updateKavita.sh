#!/bin/bash

printf "##################################################################################\n"
printf "# updateKavita.sh -- A simple upgrade script based on the official steps at...   #\n"
printf "#   https://wiki.kavitareader.com/guides/updating/updating-native/               #\n"
printf "#                                                                                #\n" 
printf "# MIT License                                                                    #\n"
printf "# Copyright (c) 2025 James Robert Wilmoth                                        #\n"
printf "#                                                                                #\n"
printf "# Permission is hereby granted, free of charge, to any person obtaining a copy   #\n"
printf "# of this software and associated documentation files (the \"Software\"), to deal  #\n"
printf "# in the Software without restriction, including without limitation the rights   #\n"
printf "# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      #\n"
printf "# copies of the Software, and to permit persons to whom the Software is          #\n"
printf "# furnished to do so, subject to the following conditions:                       #\n"
printf "#                                                                                #\n"
printf "# The above copyright notice and this permission notice shall be included in all #\n"
printf "# copies or substantial portions of the Software.                                #\n"
printf "#                                                                                #\n"
printf "# THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     #\n"
printf "# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       #\n"
printf "# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    #\n"
printf "# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         #\n"
printf "# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  #\n"
printf "# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  #\n"
printf "# SOFTWARE.                                                                      #\n"
printf "##################################################################################\n"

printf "\nHere is an outline of the update process in this script:\n"
printf "1. Validate the package you specified\n"
printf "2. Stop the kavita service\n"
printf "3. Remove any previously extracted temp folder for kavita\n"
printf "4. Download the package you specified\n"
printf "5. Extract the downloaded file\n"
printf "6. Remove the default config folder from the extraction to preserve your existing config\n"
printf "7. Make a backup of /opt/Kavita\n"
printf "8. Copy the extracted update over /opt/Kavita\n"
printf "9. Set the ownership and permissions on the /opt/Kavita folder\n"
printf "10. Start the kavita service\n"
printf "11. Loop the kavita service status so you can monitor for completion of any migrations before you continue with another update or testing\n\n" 

printf "\nDo you wish to proceed? " && read answer
if ! [[ "$answer" =~ ^[yes|YES|y|Y]$ ]]; then
	printf "\nAborting update...\n\n"
	exit 1
fi	

if [ -n "$1" ]; then
	if [[ "$1" =~ ^https\:\/\/github\.com\/Kareadita\/Kavita\/releases\/download\/.*\/kavita\-.*\-.*\.tar\.gz$ ]]; then
		printf "\nThe URL you provided on the CLI is valid. However, are you sure this is the right file for your system architecture? " && read answer
		if ! [[ "$answer" =~ ^[yes|YES|y|Y]$ ]]; then
			printf "\nAborting update so you can double check your architecture and the file to download.\n\n"
			exit 1
		fi	
		printf "\nPackage will be downloaded from $1.\n\n" 
	else
		printf "\nFailed to validate the URL. This script is designed to download only packages from the official kavita github release page.\n"
		printf "\nExample: https://github.com/Kareadita/Kavita/releases/download/v0.8.6.2/kavita-linux-x64.tar.gz\n\n"
		exit 1
	fi
else
	printf "\nPlease specify a package URL as the only parameter. Aborting.\n\n"
	exit 1
fi

printf "\nStopping the kavita service...\n\n" && sleep 1
systemctl stop kavita
if [ $? -eq 0 ]; then
	printf "\nKavita service stopped.\n\n"
else
	printf "\nFailed to stop Kavita service. Aborting.\n\n"
	exit 1
fi
sleep 3

printf "\nDeleting any previously extracted temp folder...\n\n" && sleep 1
if [ -d ./Kavita ]; then
	rm -R ./Kavita
	if [ $? -eq 0 ]; then
		printf "\nPrevious package extracted folder deleted.\n\n"
	else
		printf "\nFailed to delete previously extracted folder. Aborting.\n\n"
		exit 1
	fi
fi

printf "\nDownloading the package you specified...\n\n" && sleep 1
wget -O "kavita-linux-x64.tar.gz" "$1"
if [ $? -eq 0 ]; then
	printf "\nPackage downloaded.\n\n"
else
	printf "\nPackage failed. URL provided was $1. Aborting.\n\n"
	exit 1
fi
sleep 3

printf "\nExtracting the download...\n\n" && sleep 1
tar xvf ./kavita-linux-x64.tar.gz
if [ $? -eq 0 ]; then
	printf "\nPackage extracted.\n\n"
else
	printf "\nPackage failed to extract. Aborting.\n\n"
	exit 1
fi
sleep 3

printf "\nDeleting the default config folder to preserve your config...\n\n" && sleep 1
rm -R ./Kavita/config
if [ $? -eq 0 ]; then
	printf "\nRemoved default config folder.\n\n"
else
	printf "\nUnable to remove default config folder. Aborting.\n\n"
	exit 1
fi
sleep 3

timestamp="$(date +'%Y%m%d_%H%M')"

printf "\nCreating a backup of the /opt/Kavita folder...\n\n" && sleep 1
tar -czf "./kavita_$timestamp.tar.gz" /opt/Kavita
if [ $? -eq 0 ]; then
	printf "\nCreated backup of existing version.\n\n"
else
	printf "\nFailed to create backup of existing version. Aborting.\n\n"
	exit 1
fi
sleep 3

printf "\nCopying the extracted files to /opt/Kavita...\n\n" && sleep 1
rsync -av ./Kavita/ /opt/Kavita
if [ $? -eq 0 ]; then
	printf "\nCopied new version over old version.\n\n"
else
	printf "\nFailed to copy new version over old version. Aborting.\n\n"
	exit 1
fi
sleep 3

printf "\nSetting ownership of the folder to kavita:kavita...\n\n" && sleep 1
chown kavita:kavita -R /opt/Kavita
if [ $? -eq 0 ]; then
	printf "\nConfigured ownership of Kavita.\n\n"
else
	printf "\nFailed to configure ownership of Kavita. Aborting.\n\n"
	exit 1
fi
sleep 3

printf "\nSetting executable permission on the kavita binary...\n\n" && sleep 1
chmod +x /opt/Kavita/Kavita
if [ $? -eq 0 ]; then
	printf "\nConfigured Kavita executable permissions.\n\n"
else
	printf "\nFailed to configure Kavita executable permissions. Aborting.\n\n"
	exit 1
fi
sleep 3

printf "\nStarting the kavita service...\n\n" && sleep 1
systemctl start kavita
if [ $? -eq 0 ]; then
	printf "\nKavita service started.\n\n"
else
	printf "\nFailed to start Kavita service. Aborting.\n\n"
	exit 1
fi
sleep 3

printf "\nMonitor the status below. If you see migrations in progress, wait until they finishe before you do another Kavita upgrade. Press CTRL+C at any time to exit return to the CLI.\n\n" && journalctl --follow -u kavita.service
