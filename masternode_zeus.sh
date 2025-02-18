#!/bin/bash
#set -x

# The author of the software is the owner of the Dash Address: XjwSnc9f81ZVC2GAyKQip5N3Apv2zumRoc


# Define some colours

txtblk='\e[0;30m' # Black - Regular
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txtylw='\e[0;33m' # Yellow
txtblu='\e[0;34m' # Blue
txtpur='\e[0;35m' # Purple
txtcyn='\e[0;36m' # Cyan
txtwht='\e[0;37m' # White
bldblk='\e[1;30m' # Black - Bold
bldred='\e[1;31m' # Red
bldgrn='\e[1;32m' # Green
bldylw='\e[1;33m' # Yellow
bldblu='\e[1;34m' # Blue
bldpur='\e[1;35m' # Purple
bldcyn='\e[1;36m' # Cyan
bldwht='\e[1;37m' # White
unkblk='\e[4;30m' # Black - Underline
undred='\e[4;31m' # Red
undgrn='\e[4;32m' # Green
undylw='\e[4;33m' # Yellow
undblu='\e[4;34m' # Blue
undpur='\e[4;35m' # Purple
undcyn='\e[4;36m' # Cyan
undwht='\e[4;37m' # White
bakblk='\e[40m'   # Black - Background
bakred='\e[41m'   # Red
badgrn='\e[42m'   # Green
bakylw='\e[43m'   # Yellow
bakblu='\e[44m'   # Blue
bakpur='\e[45m'   # Purple
bakcyn='\e[46m'   # Cyan
bakwht='\e[47m'   # White
txtrst='\e[0m'    # Text Reset



# Takes one param, the number of chars to print.
busyLoop(){
	local i
	(( $# < 1 )) && return 1
	[[ "$1" =~ ^[0-9]+$ ]] || return 2
	i=$1
	while ((i--)) ;do
		c=$(( RANDOM % 16 ))
		echo -en "\\e[48;5;${c}m "
	done
	echo -e '\e[0m'
}


# The function takes two arguments, the size or the progress bar to display in chars
# and the percent complete.
# Will print part of the progress bar each time it is called, valid ranges are
# 0 to 100.  The function must be called with 100 to complete the progress bar
# and reset the terminal.
# An optional 3rd arg can be given to display as text to left of the progress bar.
printGraduatedProgressBar(){

	(( $# < 2 )) && return 1
	[[ "$1" =~ ^[0-9]+$ ]] || return 2
	(( $1 < 9 || $2 > 121 )) && return 3
	[[ "$2" =~ ^[0-9]+$ ]] || return 4
	(( $2 < 0 || $2 > 100 )) && return 5

	local spaces
	# progress must remain as a global variable.
	#local progress
	local step

	# Create the progress bar area and return the cursor to the left (D)
	# Up (A), Down (B), Right (C), Left (D)
	if (( $2 == 0 ));then
		spaces=
		progress=0
		for ((i=0; i<$1; i++));do spaces+=" ";done
		[[ -n "$3" ]] && text="$3 "
		echo -en "\\e[1;37m${text}[$spaces]\\e[0m\\e[$(($1+1))D"
	fi
	step=$((100 / $1))
	# Due to rounding, sometimes the step is too small causing overshoot
	# adjust for that.
	(($((step * $1))<100))&&((step++))
	while((progress<$2));do
		((progress+=step))
		echo -en "\\e[48;2;0;$((progress * 2 + 20));0m "
	done

	(( $2 == 100 )) && echo -e '\e[0m'
}


# 1st parameter is the number of blocks to print, it is mandatory.
# 2nd parameter is between 1 and 300 for the speed of the variance,
# 1 is the slowest, this parameter is optional.
# 3rd parameter is for the intensity, between 1 and 900, higher
# numbers tend to black, lower numbers tend to white.
busyLoop24bit(){
	(( $# < 1 )) && return 1
	[[ $1 =~ ^[0-9]+$ ]] || return 2
	local i
	local speed
	local intensity
	local r
	local g
	local b
	local r_delta
	local g_delta
	local b_delta
	i=$1
	[[ -z $2 ]] && speed=20||speed=$2
	[[ -z $3 ]] && intensity=42||intensity=$3
	[[ $speed =~ ^[0-9]+$ ]] || return 3
	[[ $intensity =~ ^[0-9]+$ ]] || return 4
	(( speed < 1 || speed > 300 )) && return 5
	(( intensity < 1 || intensity > 900 )) && return 6

	r=0;g=0;b=0
	while ((i--)) ;do
		r_delta=$(( speed - RANDOM % intensity ))
		g_delta=$(( speed - RANDOM % intensity ))
		b_delta=$(( speed - RANDOM % intensity ))

		r=$((r + r_delta))
		g=$((g + g_delta))
		b=$((b + b_delta))

		((r<0))&&r=0;((r>255))&&r=255
		((g<0))&&g=0;((g>255))&&g=255
		((b<0))&&b=0;((b>255))&&b=255

		echo -en "\\e[48;2;$r;$g;$b""m "
	done
	echo -e '\e[0m'
}



# Checks if the logged in user is root or not, if it is not root, checks to see if the logged in user
# has sudo to root.
# Returns:
# 0 for non-root user with sudo to root
# 1 for root user
# 2 for non-privileged user with no sudo to root

idCheck(){
	(( $(id -u) == 0 )) && return 1
	msg="$ZEUS is now checking if you have sudo access to the root account\\n"
	msg+="from this user $(whoami). You may be prompted for your password now.\\n"
	msg+="Enter your user's password when prompted NO CHANGES will be made at this time,\\n"
	msg+="this is just a check.\\n"
	echo -e "$msg"
	local sid
	sid=$(sudo id -u)
	(( $? != 0 )) && return 2
	(( sid == 0 )) && { MNO_USER=$(whoami);return 0;}
}



# Checks the Operating system for compatibility with this tool.
# Returns 0 for successful confirmation of Debian or Ubuntu OS.
# Returns 1 for Raspbian.
# Returns 2 for Fedora - Maybe be a supported OS in a later version
# Returns 9 for all other OSes.

osCheck(){
	# First check for Raspberry Pi, it can sometimes pass as Debian as well.
	if { cat /etc/hostname /proc/cpuinfo;uname -n;hostnamectl;}|grep -qiE raspberry.?pi;then
		echo "OS Check passed, operating system is Raspberry Pi OS."
		return 1
	fi
	if grep ^NAME /etc/os-release|grep -qi "Ubuntu\|Debian";then
		echo "OS Check passed, operating system is Debian based."
		return 0
	elif grep ^NAME /etc/os-release|grep -qi Raspbian;then
		echo "OS Check passed, operating system is Raspbian."
		return 1
	elif grep ^NAME /etc/os-release|grep -qi Fedora;then
		echo "Fedora is not a currently supported OS, please install and manage your masternode manually."
		return 2
	else
		echo "Cannot identify your system, please install and manage your masternode manually."
	fi
	return 99
}

# Will print a random string that can be used for password, if a numerical parameter is given,
# then it will be used as the length of the string.
getRandomString(){
	local length
	length=${1:-32}
	< /dev/urandom tr -dc A-Za-z0-9 | head -c"${length}";echo
}

createMnoUser(){

	local option
	msg="Creating the mno user.\\n"
	msg+="If you have not yet reset your root password, it is recommended to do so now.\\n"
	msg+="Would you like to reset the password of the root user? [[${bldwht}Y${txtrst}] n] "
	echo -en "$msg"
	read -r -n1 option
	echo -e "\\n$option">>"$LOGFILE"
	echo
	local setpasswd
	option=${option:-Y}
	[[ $option = [yY] ]] && while ! passwd ;do : ;done
	echo

	if grep -q ^mno /etc/passwd;then
		echo "Found existing mno user on this system."
		grep mno /etc/group|grep -q sudo || { echo "Adding mno to the sudo group";usermod -aG sudo mno; }
		echo -en "Would you like to reset the password of the mno user? [y [${bldwht}N${txtrst}]] "
		read -r -n1 option
		echo -e "\\n$option">>"$LOGFILE"
		echo
		option=${option:-Y}
		[[ $option = [yY] ]] && setpasswd="Y"
	else
		echo "There is no mno user on this system, creating it now."
		# Attempt to delete the group in case this is a rogue entry.
		groupdel mno >/dev/null 2>&1
		if ! useradd -m -c "Dash Admin" mno -s /bin/bash -G sudo;then
			msg="Could not create user, this is bad.\\n"
			msg+="There may be some remnants of it in the passwd or group or shadow files.\\n"
			msg+="Check those files and clean them up and try again."
			echo -e "$msg"
			exit 1
		fi
		setpasswd="Y"
	fi

	if [[ -n $setpasswd ]];then
		msg="You will now be prompted to set a password for the mno user.\\n"
		msg+="Choose a long password and write it down, do not loose this password.\\n"
		msg+="It should be at least 14 characters long.  Below is a secure and unique password\\n"
		msg+="you can use for this account, be sure to keep a copy in your password vault if you do.\\n\\n"
		msg+="${bldwht}$(getRandomString 32)${txtrst}\\n\\n"
		echo -e "$msg"
		while ! passwd mno;do : ;done
		echo
		read -r -s -n1 -p "Press any key to continue. "
		echo
	fi

	[[ ! -d /home/mno/bin ]] && mkdir /home/mno/bin
	cp "$ZEUS" /home/mno/bin&&chown -R mno:mno /home/mno/bin

	msg="The mno user is now ready to use, please logout and log back in as the mno user\\n"
	msg+="to continue with setting up your masternode. This script has been copied to the bin directory of the\\n"
	msg+="mno user, when you have logged back in as mno, you can continue this script by typing in ${bldwht}$(basename "$ZEUS")${txtrst}\\n"
	echo -e "$msg"
	read -r -s -n1 -p "Press any key to continue. "
	echo
}

removeUnusedAccounts(){
	echo "Removing unnecessary accounts..."
	local users
	local user
	users="ubuntu linuxuser"
	for user in $users;do
		sudo userdel -r "$user"
		sudo groupdel "$user"
	done >/dev/null 2>&1
}

createDashUser(){

	local option
	local setpasswd
	if grep -q ^dash /etc/passwd;then
		echo "Found existing dash user on this system."
		sudo usermod -aG dash dash
		echo -en "Would you like to reset the password of the dash user? [[${bldwht}Y${txtrst}] n] "
		read -r -n1 option
		echo -e "\\n$option">>"$LOGFILE"
		echo
		option=${option:-Y}
		[[ $option = [yY] ]] && setpasswd="Y"
	else
		echo "Creating the dash user."
		# Attempt to delete the group in case this is a rogue entry.
		sudo groupdel dash >/dev/null 2>&1
		if ! sudo useradd -m -c dash dash -s /bin/bash;then
			msg="Could not create user, this is bad.\\n"
			msg+="There may be some remnants of it in the passwd or group or shadow files.\\n"
			msg+="Check those files and clean them up and try again."
			echo -e "$msg"
			exit 1
		fi
		setpasswd="Y"
	fi


	if [[ -n $setpasswd ]];then
		msg="The password for the dash user should be set to something completely random.\\n"
		msg+="You will never need it for anything. A random password has been generated for you below\\n"
		msg+="and set for the dash user you can keep a copy if you like, but it is not required.\\n"
		echo -e "$msg"
		dashpw=$(getRandomString 32)
		echo -e "${bldwht}$dashpw${txtrst}\\n\\n"
		echo "dash:$dashpw"|sudo chpasswd
		read -r -s -n1 -p "Press any key to continue. "
		echo
	fi

	# Finally add the mno user to the dash group.
	sudo usermod -aG dash "$MNO_USER"
}




preventRootSSHLogins(){
	grep ^PermitRootLogin /etc/ssh/sshd_config |tail -1|grep -q "PermitRootLogin no"\
	&& { echo "Login as root via ssh is already disabled, continuing...";return 0;}
	msg="**** Disabling root logins from ssh connections. ****\\n\\n"
	msg+="For security reasons we want to disable remote logins to the root user from now on.\\n"
	msg+="The root user exists on every UNIX/Linux machine and its password is being brute force\\n"
	msg+="attacked all the time!  From now on you must *always* logon with the $(whoami) user."
	echo -e "$msg"
	if (( $(id -u) != 0 )); then
		sudo bash -c \
		"grep -q \".*PermitRootLogin [ny][oe].*\" /etc/ssh/sshd_config &&\
		sed -i 's/.*PermitRootLogin [ny][oe].*/PermitRootLogin no/g' /etc/ssh/sshd_config||\
		echo \"PermitRootLogin no\">>/etc/ssh/sshd_config"
	else echo "Only run this block as your Dash Admin ($MNO_USER) user, not root."; fi
	read -r -s -n1 -p "Press any key to continue. ";echo
}

uninstallJunkPackages(){
	# This is not required for Raspberry Pi.
	((OS==1))&&return
	# Removing this list of programs should be safe for running of masternode and infact should make it more secure since
	# tmux and screen are good ways for hackers to hide their running sessions.
	# Remove polkit because CVE was discovered in it and it seems to be pretty much useless.
	# Doing it like this because if any one of the packages is unknown to the package manager, apt will do nothing, so remove them one by one.
	echo "Uninstalling unnecessary programs..."
	local packages
	local package
	local service
	packages="screen tmux rsync usbutils pastebinit netcat netcat-openbsd libthai-data libthai0 eject ftp dosfstools command-not-found wireless-regdb ntfs-3g snapd libmysqlclient21 g++-10 gcc-10 policykit-1 libpolkit-gobject-1-0 popularity-contest apache2-utils"
	for package in $packages
	do
		echo "*** Removing $package ***"
		sudo apt-get -y remove "$package" --purge
	done
	# After removing all this cruft, I found the following was also needed to make systemd stop trying to bring up removed services.
	for service in apparmor.service console-setup.service snap.lxd.activate.service
	do
		sudo systemctl disable "$service"
	done

	sudo apt-get -y autoremove --purge
	sudo apt-get autoclean
	sudo apt-get clean
}

updateSystem(){
	msg="Updating your system using apt update/upgrade.\\n"
	msg+="Answer any prompts as appropriate...\\n"
	echo -e "$msg"

	# Doing it like this because on a fresh system it is possible a background task is locking the package manager causing this to fail for some time.
	until sudo apt-get update&&sudo apt-get upgrade;do echo "Trying again, please wait...";sleep 30;done

	uninstallJunkPackages

	echo "Finished applying system updates."

	echo " Install additional packages needed for masternode operation..."
	sudo apt-get -y install ufw git patch curl wget tor unzip pv bc jq speedtest-cli hdparm net-tools catimg &&\
	sudo apt-get autoremove --purge &&\
	sudo apt-get clean && echo "Additional packages were installed successfully..." ||\
	{ echo "There was an error installing the additional packages, exiting...";exit 2; }
}


enableFireWall(){
	# This is not required for Raspberry Pi.
	((OS==1))&&return
	echo "Checking for a firewall..."
	local firewall
	firewall=$(sudo ufw status)
	grep -q "^22.tcp\ *[LA][IL][ML]" <<<"$firewall" &&\
	grep -q "^9999.tcp\ *[LA][IL][ML]" <<<"$firewall"
	if (( $? != 0 ));then
		echo "Setting up a firewall..."
		sudo ufw allow ssh/tcp &&\
		sudo ufw limit ssh/tcp &&\
		sudo ufw allow 9999/tcp &&\
		sudo ufw logging on &&\
		sudo ufw enable &&\
		echo "Firewall configured successfully!" ||\
		echo "Error enabling firewall."
	else
		echo "Your firewall is OK."
	fi
}

configureSwap(){
	# This is not required for Raspberry Pi.
	((OS==1))&&return
	echo "Checking your available swap space..."
	local swapfile
	if (( $(free -m|awk '/Swap/ {print $2}') < 3096 ));then
		echo "Adding 3GB swap..."
		swapfile="/var/swapfile"
		[[ -f /var/swapfile ]] && swapfile="$swapfile.$RANDOM"
		sudo bash -c "fallocate -l 3G \"$swapfile\"&&\
		chmod 600 \"$swapfile\"&&\
		mkswap \"$swapfile\"&&\
		swapon \"$swapfile\"&&\
		grep -q \"^\"$swapfile\".none.swap.sw.0.0\" /etc/fstab ||\
		echo -e \"\"$swapfile\"\tnone\tswap\tsw\t0\t0\" >>/etc/fstab"
		(( $? != 0 )) && echo "Error adding swap."
	else
		echo "You already have enough swap space."
	fi
}

# Re-runable function to configure TOR for dash.
configureTOR(){
	echo "Configuring TOR..."
	local x
	x=$(grep -c "^Co[no][tk][ri]" /etc/tor/torrc)
	if((x != 3));then
		sudo bash -c "echo -e 'ControlPort 9051\nCookieAuthentication 1\nCookieAuthFileGroupReadable 1' >> /etc/tor/torrc"
	fi
	sudo systemctl enable --now tor
	sleep 1
	local group
	group=$(procs=$(ps -A -O pid,ruser:12,rgroup:12,comm);grep $(pidof tor)<<<"$procs"|awk '{print $3}')
	if((PIPESTATUS == 0));then
		sudo usermod -aG "$group" dash
	else
		echo "Error detecting the tor group name."
	fi
	sudo systemctl restart tor
}

# Re-runnable.
increaseNoFileParam(){
	echo "Checking open file limits..."
	local nofile
	nofile=$(sudo grep -v ^# /etc/security/limits.conf|grep dash|grep -o "nofile.*"|tail -1|awk '{print $2}')
	[[ -z $nofile ]] && nofile=0
	if ((nofile!=4096));then
		echo "Adjusting nofile limit in limits.conf"
		sudo sed -i 's/\(dash.*nofile.*\)/#\1/g' /etc/security/limits.conf
		echo "dash - nofile 4096"|sudo tee -a /etc/security/limits.conf
	fi
	if ! sudo grep -v ^# /etc/systemd/system.conf|grep -q DefaultLimitNOFILE=4096;then
		echo "Adjusting nofile limit in system.conf"
		sudo sed -i 's/\(^DefaultLimitNOFILE=.*\)/#\1/g' /etc/systemd/system.conf
		echo "DefaultLimitNOFILE=4096:524288"|sudo tee -a /etc/systemd/system.conf
	fi
}


# Returns:-
# 0 if the change was made
# 1 is no change was necessary.
addSysCtl(){
	sudo grep -q "^vm\.overcommit_memory" /etc/sysctl.conf\
	&& return 1\
	|| { echo "Adjusting kernel parameter in /etc/sysctl.conf to optimise RAM usage.";sudo bash -c "echo \"vm.overcommit_memory=1\">>/etc/sysctl.conf";}
}

rebootSystem(){
	msg="A reboot is required at this time to allow the changes to take effect\\n"
	msg+="and to verify the system is still working correctly.\\n"
	echo -e "$msg"
	read -r -s -n1 -p "Press any key when ready to reboot. "
	echo
	sudo reboot
}


# We want to store the Pasta key in the key store of this user, but we need to verify several sources.
# exit codes
# 0 - Added to keystore or already present.
# 1 - Failed download of key.
# 2 - Failed verification of key.
# 3 - Key is revoked.
addKeyToStore(){
	local id
	local error
	id="29590362ec878a81fd3c202b52527bedabe87984"
	# Attempt to refresh the key (if it exists) to get revocation information in case it is revoked.
	echo "Refreshing Pasta's public key, if possible..."
	gpg --refresh-keys $id || gpg --keyserver hkp://keyserver.ubuntu.com --refresh-keys $id
	# Check if we already have the Pasta key.
	if gpg -k|grep -q -i $id;then
		gpg -k $id|grep -q -i revoked &&\
		{ echo "This Pasta key is revoked!  We cannot trust this key, we cannot continue to download the binaries.";return 3;}
		return
	fi

	echo "Downloading Pasta's public key for verification of Dash Core builds..."
	wget -q -O/tmp/pasta_1.pgp https://keybase.io/pasta/pgp_keys.asc?fingerprint=29590362ec878a81fd3c202b52527bedabe87984 || error=yes
	wget -q -O/tmp/pasta_2.pgp "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x29590362ec878a81fd3c202b52527bedabe87984" || error=yes
	wget -q -O/tmp/pasta_3.pgp https://gist.githubusercontent.com/PastaPastaPasta/ae19c1826a91a9c8d126150e903df7e0/raw/6a232f7fad99ee729177883056b8716d79380e73/pasta.pgp || error=yes

	if [[ -n $error ]];then
		echo "There was an error downloading the public keys, aborting...";return 1
	fi
	error=

	echo "Verifying Pasta's public key..."
	gpg /tmp/pasta_1.pgp | grep -q -i $id || error=yes
	gpg /tmp/pasta_2.pgp | grep -q -i $id || error=yes
	gpg /tmp/pasta_3.pgp | grep -q -i $id || error=yes
	if [[ -n $error ]];then
		echo "There was an error verifying the public key, aborting...";return 2
	fi
	error=

	echo "Adding Pasta's key to the keystore..."
	gpg --import /tmp/pasta_1.pgp
}

downloadDashd(){
	echo "Starting Download of dashcore..."
	echo "Checking machine type to determine package for download..."
	local mach
	local arch
	local error
	# Try to be smart and determine arch of this host.
	mach=$(uname -m)
	case $mach in
		armv7l)
			arch="arm-linux-gnueabihf"
			;;
		aarch64)
			arch="aarch64-linux-gnu"
			;;
		x86_64)
			arch="x86_64-linux-gnu"
			;;
		*)
			msg="ERROR: Machine type ($mach) not recognised.\\n"
			msg+="Could not download the dashcore binaries.  Aborting..."
			echo -e "$msg"
			return 1
			;;
	esac
	cd /tmp
	wget -q -O SHA256SUMS.asc https://github.com/dashpay/dash/releases/latest/download/SHA256SUMS.asc ||\
	{ echo "Download of SHA256SUMS.asc has failed!  Aborting..."; return 2;}
	echo "Download of SHA256SUMS.asc completed successfully!"
	local awk_string
	awk_string="awk '/dashcore.*$arch.*.tar.gz/ {print \$2}' SHA256SUMS.asc"
	local filename
	filename=$(eval "$awk_string")
	wget -q -O "$filename" https://github.com/dashpay/dash/releases/latest/download/"$filename" || error=yes
	wget -q -O "${filename}.asc" https://github.com/dashpay/dash/releases/latest/download/"${filename}.asc" || error=yes
	[[ -n "$error" ]] && { echo "There was an error downloading $filename and/or ${filename}.asc.  Aborting...";return 3;}

	echo "$filename" >.filename
}

verifyDashd(){
	local filename
	filename="$1"
	[[ -z "$filename" ]] && { echo "A filename is required to verify dashd.";return 1;}
	if gpg --verify "${filename}.asc" "$filename";then
		echo "$filename has verified successfully!"
	else
		echo "$filename has NOT verified successfully, cannot continue!"
		return 2
	fi
}

installDashd(){
	local filename
	filename="$1"
	[[ -z "$filename" ]] && { echo "A filename is required to install dashd.";return 1;}
	[[ -z "$INSTALL_LOCATION" ]] && { echo "I don't know where to install! Check the variable INSTALL_LOCATION.";return 2;}
	# Now let's install it!
	echo "Installing the dashcore package..."
	cd "$INSTALL_LOCATION" ||\
	{ echo "Install location $INSTALL_LOCATION is not accessible.  Aborting...";return 5;}
	local base_dir
	base_dir=$(basename $(tar tf /tmp/"$filename" |head -1))
	sudo tar xf /tmp/"$filename" ||\
	{ echo "Failed to extract the archive, check that tar is working.  Aborting...";return 6;}
	sudo rm -f dash >/dev/null 2>&1
	sudo ln -s "$base_dir" dash
	[[ -f dash/bin/dashd ]] ||\
	{ echo "dashd is not accessible via the symlink.  Aborting...";return 7;}
	ldd dash/bin/dashd >/dev/null 2>&1 ||\
	{ echo "dashd is not executable on this machine, possible cause is the wrong architecture was downloaded for this system.  Aborting...";return 8;}
}



# Re-runnable, it will only make the change once.
configureManPages(){
	echo "Adding Dash man pages to the MANPATH..."
	sudo bash -c "grep -q \"^MANPATH_MAP.*/opt/dash/bin.*/opt/dash/share/man\" /etc/manpath.config||\
					echo -e \"MANPATH_MAP\t/opt/dash/bin\t\t/opt/dash/share/man\">>/etc/manpath.config"
}

# Re-runnable, it will only make the change once.
# This is specific to Debian based OSes only.
# Each argument is the username to adjust.

configurePATH(){
	# Exit if no arguments given.
	(($#<1))&&return;
	# Exit if I am unfamiliar with how the shell is setup on this OS.
	osCheck >/dev/null 2>&1
	(( $? > 1 ))&&{ echo "Your operating system is not supported, please edit your PATH manually.";return;}
	# For each parameter (user) adjust their PATH if required.
	while :;do
		# Exit if this parameter is empty.
		[[ -z "$1" ]]&&break
		echo "Adding Dash binaries to the PATH of the $1 user..."
		sudo bash -c "grep -q '^\[\[ -d /opt/dash/bin \]\]&&PATH=\$PATH:/opt/dash/bin' /home/$1/.profile||\
			echo '[[ -d /opt/dash/bin ]]&&PATH=\$PATH:/opt/dash/bin'>>/home/$1/.profile"
		# Move the parameters down and exit when they are all consumed.
		shift||break
	done
}


createDashConf(){
	# Configure a bare bones dash.conf file.
	[[ -z $DASH_CONF ]] && { echo "DASH_CONF is not defined, cannot set this up now.";exit 1;}
	local option
	if sudo test -f "$DASH_CONF";then
		echo "******************** $DASH_CONF ********************"
		sudo cat "$DASH_CONF"
		echo "******************** $DASH_CONF ********************"
		msg="A dash.conf file already exists at $DASH_CONF\\n"
		msg+="It is displayed on the screen above this text. Would you like to overwrite\\n"
		msg+="this file? Recommend to not overwrite, especially if your masternode is working.\\n"
		msg+="Overwrite dash.conf? [y [${bldwht}N${txtrst}]] "
		echo -en "$msg"
		read -r -n1 option
		echo -e "\\n$option">>"$LOGFILE"
		echo
		option=${option:-N}
		if [[ $option = [nN] ]]
		then
			return 1
		else
			local dash_conf_bak
			dash_conf_bak="$DASH_CONF-"$(date +"%Y%m%d%H%M")
			sudo -u dash bash -c "cp \"$DASH_CONF\" \"$dash_conf_bak\""
			echo "A backup has been made of your existing dash conf at $dash_conf_bak"
		fi
	fi

	# We will try and populate as much as is possible in the below template.
	echo "Initialising a default dash.conf file for you...."
	local rpcuser
	local rpcpassword
	local ip
	local bls_key
	rpcuser=$(getRandomString 40)
	rpcpassword=$(getRandomString 40)
	ip=$(curl -4s https://icanhazip.com/)||ip=$(curl -4s https://ipecho.net/plain)
	(( $? != 0 || ${#ip} < 7 || ${#ip} > 15 ))&& ip="XXX.XXX.XXX.XXX"

	msg="Next you need your bls private that you got from the 'bls generate' command\\n"
	msg+="in the core walletor from DMT.\\n"
	msg+="Note: This is NOT your collateral private key !\\n"
	msg+="Please enter your bls private (secret) key, if you don't have it ready,\\n"
	msg+="just type in 'default' and edit your $DASH_CONF file later."
	echo -e "$msg"
	option='n'
	until [[ "$option" = 'Y' || "$option" = 'y' ]];do
		read -r -n64 -p "bls key " bls_key
		echo -en "You entered a bls key of ${bldwht}\"$bls_key\"${txtrst}.\\nPress 'Y' to accept, '${bldwht}N${txtrst}' to re-enter. "
		read -r -n1 option
		echo -e "\\n$option">>"$LOGFILE"
		echo
		option=${option:-N}
	done
	# Case insensitive match.  Set some random bls key because the masternode won't start without it.
	[[ ${bls_key,,} = "default" ]]&& bls_key="000000c757797986f29fb529ad5352de587f7c9ecdfd1ff727e572fa193e0dec"
	echo "Creating dash.conf file..."
	sudo -u dash bash -c "mkdir -p $(dirname "$DASH_CONF")&&cat >\"$DASH_CONF\"<<\"EOF\"
#----
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
#----
listen=1
server=1
daemon=1
#----
masternodeblsprivkey=$bls_key
externalip=$ip
#----
proxy=127.0.0.1:9050
torcontrol=127.0.0.1:9051
#----
EOF"
}

editDashConf(){
	[[ -z $DASH_CONF ]] && { echo "DASH_CONF is not defined, cannot set this up now.";exit 1;}
	msg="Once you are done editing this file exit with CTRL + X and answer Y to save,\\n"
	msg+="if you're using vi, press ESC, then type in :wq to write and quit."
	echo -e "$msg"
	read -r -s -n1 -p "Press any key to continue. "
	echo
	if test -x $(which nano);then
		# Since nano wont work right without a stderr, I am re-establishing a stderr from
		# the copy I saved earlier and then after nano is done I tie stderr to stdout again
		# so that the tee can continue log everything.
		exec 2>&4
		sudo -i -u dash bash -c "nano $DASH_CONF"
		exec 2>&1
	elif test -x $(which vi);then
		exec 2>&4
		sudo -i -u dash bash -c "vi $DASH_CONF"
		exec 2>&1
	else
		echo "Could not find an editor on you machine, remember to edit the file $DASH_CONF yourself later."
	fi
}

# Next we wish to register the `dashd` deamon as a system process so that is starts
# automatically when the VPS boots and shutdown automatically when the VPS shuts down,
# it will also restart the process if it should crash for some reason.
createDashdService(){
	[[ -f /etc/systemd/system/dashd.service ]] &&\
	{ echo "Systemd dashd unit file already exists, skipping...";return 1;}
	# Gotta escape the " with \ in the here document.
	sudo mkdir -p /etc/systemd/system&&\
	sudo bash -c "cat >/etc/systemd/system/dashd.service<<\"EOF\"
[Unit]
Description=Dash Core Daemon
Documentation=https://dash.org/
Requires=network-online.target
After=network-online.target

# Watch the daemon service actions in the syslog journal with:
# sudo journalctl -u dashd.service -f

[Service]
Type=forking
User=dash
Group=dash

ExecStart=/opt/dash/bin/dashd
# Time that systemd gives a process to start before shooting it in the head
TimeoutStartSec=10m

# If ExecStop is not set, systemd sends a SIGTERM, which is \"okay\", just not ideal
ExecStop=/opt/dash/bin/dash-cli stop

# Time that systemd gives a process to stop before shooting it in the head
TimeoutStopSec=300

Restart=on-failure
RestartSec=120

# Allow for three failures in five minutes before trying to spawn another instance
StartLimitInterval=300
StartLimitBurst=3

# If the OOM kills this process, systemd should restart it.
OOMPolicy=continue
IPAccounting=yes
IOAccounting=yes
PrivateTmp=true

[Install]
WantedBy=multi-user.target

EOF"

	# Next we register with systemd which controls all the processes (daemons) running
	# on the VPS and ask it to enable `dashd` at boot and to launch it for the first time.

	sudo systemctl daemon-reload &&\
	sudo systemctl enable --now dashd &&\
	echo "Dash is now installed as a system service and initializing..." ||\
	echo "There was a problem registering and starting the dashd daemon via systemd."
}

createTopRC(){
	# We wont overwrite your .toprc if you already have one.
	[[ -f ~/.toprc ]] && return 1
	echo "Configuring ~/.toprc"
	echo "H4sICIxNGGMAAy50b3ByYwC11Elv00AUAOBz/Ct8ogmYYntsk0LcliYKdElZ2rKUxTj22JnW4zEz
duPyf6AVJ6QWRU0IFJH8L8ZVpHEPXFC4jN7TLO99erJTkiwwuUniAIVyG0VQrm6hOMvlhBIPMgaZ
3Edpjy+xT/qsJq379w4UuUN86LhRyjxqq7MUUZQnzNYUuQUj99hJEYY2WOTbzYzy+7YqtWBQCRCM
fOZl1P50enb+bfR9fDkZDC+mNxZqN28ptxfvqJpu1ZdXHqw12w8frW9sbnW2Hz95+mxnd+/5i5ev
9l+/efvOee92PR8GYQ8dHEY4JskHytLsqJ8ff5QqvFYQuSFvxQK6qSsyIzTl/ee2Vldk7Oapyw5Z
0XdI3aTneElWyjDEV5lPsm4EnSwpRB7BXRTD2VGpwjKMvYgWW5iFbBb2oOsXIVDkokQR6tIG6ZbN
ny8Gw+rZ+WQ0Xm2cTAXZnJd5CdQNo2RW/4Ws/p1sCbIlyHcF2ZI6EJfJw1Fj/OPn5a/O2vbvFjAG
fNTVa/ClGXpeZF2bs9kUZlOYDWE2pT1Gr4355PTLVz7qybR2BdV0YHDp/Ya9vLL6P8YM5kwGggwE
WRdkILVRDn2nj3zI0uKpHX7VwcxzI1h8Dbv8YCndh5Q4LEsSyn8rvJL0B+aNueJ7BAAA"|base64 -d|zcat >~/.toprc
	# Test top, because this toprc may not work with different versions of top
	top -v >/dev/null 2>&1|| rm -f ~/.toprc
}


installRootCrontab(){
	echo "Configuring root's crontab..."
	local root_crontab
	root_crontab=$(sudo crontab -u root -l)
	grep -q "weekly systemctl restart dashd" <<< "$root_crontab" ||\
	root_crontab+=$(echo -e "\n@weekly systemctl restart dashd")
	sudo crontab -u root - <<< "$root_crontab"&&\
	echo "Successfully installed root cron."||\
	echo "Failed to install root cron."
}

# We want the debug log file to be viewable by the MNO user too.
changePermsDebugLog(){
	local file
	local i
	i=3
	file="/home/dash/.dashcore/debug.log"
	while ((i--));do
		[[ -r "$file" ]] || sudo chmod og+r "$file" && break
		sleep 1
	done
}

installMasternode(){

	echo "Installing the DASH Masternode."
	# This section will run again after the first reboot, it should be fairly harmless and quick
	# but in the future I might jump over this block if the dash user already exists on the system.
	removeUnusedAccounts
	createDashUser
	preventRootSSHLogins
	updateSystem
	enableFireWall
	configureSwap
	configureTOR
	increaseNoFileParam
	addSysCtl && rebootSystem

	if ! sudo -u dash whoami >/dev/null 2>&1;then
		msg="Cannot run a command as the dash user. Check that the dash user exists\\n"
		msg+="and that this user $(whoami) has the correct permissions to sudo."
		echo -e "$msg"
		read -r -s -n1 -p "Press any key to exit. "
		echo
		return 2
	fi

	# To have gotten this far all the checks for a dash user and sudo access have passed.
	# Also, the system has been configured for a Dash MN, eg swap, sysctl, F/W, updates...
	# It is important that each of these functions work correctly, we cannot proceed if
	# any one of them fail, hence the extra checks below.

	# Re-running this section on a working masternode should not harm it so long as the user
	# enters the default options which is to not make breaking changes.
	addKeyToStore || { echo "The was a problem with adding Pasta's key to the keystore, please resolve this before trying to continue.";exit 1;}
	downloadDashd || { echo "Download of dashd has failed, exiting.";exit 1;}
	filename=$(</tmp/.filename)
	verifyDashd "$filename" || { echo "The downloaded file $filename does not verify as legit, please resolve this before trying to continue.";exit 1;}
	installDashd "$filename" || { echo "Failed to install dashd to the system, please resolve this error before trying to continue.";exit 1;}
	configureManPages
	configurePATH dash "$MNO_USER"
	createDashConf
	# The below also starts the dashd daemon.
	createDashdService
	changePermsDebugLog
	createTopRC
	installRootCrontab

	read -r -s -n1 -p "Installation has completed successfully, press any key to continue. "
	echo
}

# Prints the speed of the primary disk.
# csv, first field is device path, second field is the result.
speedTestDisk(){
	local data
	local disk
	local line
	data=$(lsblk -ni)
	while IFS= read -r line;do
		grep -q "disk $" <<< "$line" && { disk=$(awk '{print $1}'<<<"$line");continue;}
		grep -q "/$" <<< "$line" && break
	done <<<"$data"
	if [[ -n $disk ]];then
		echo -n "/dev/$disk,"
		sudo hdparm -t /dev/"$disk"|awk -F= '/Timing/ {gsub(/^[ \t]+/,"",$2); print $2}'
	fi
}


# Enter parameter 1 as the block time and out comes the time as a string.
convertBlocksToTime(){

	local block_time
	local mins
	block_time="2.625"
	(( $# != 1 )) && return 1
	[[ "$1" =~ ^[0-9]+$ ]] || return 2
	mins=$(echo "scale=4;$block_time * $1"|bc -l)
	if (( $(echo "$mins>2880"|bc -l) ));then
		echo "$(echo "scale=2;$mins/60/24"|bc) days"
	elif (( $(echo "scale=2;$mins>300"|bc -l) ));then
		echo "$(echo "$mins/60"|bc) hours"
	else
		echo "$mins minutes"
	fi
}

# Takes no params.
# Returns the number of lines printed.
showStatus(){

	local cpu
	local disk
	local disk_size
	local disk_used
	local disk_free
	local disk_path
	local disk_speed
	local ram
	local ram_size
	local ram_used
	local ram_free
	local swap_size
	local swap_used
	local swap_free
	local external_ip
	local port_9999
	local local_port_9999
	local dashd_version
	local dashd_procs
	local all_procs
	local num_dashd_procs
	local dashd_pid
	local dashd_user
	local i
	local p
	local block_height
	local blockchair_height
	local num_peers
	local masternode_status
	local pose_score
	local enabled_mns
	local mn_sync
	local last_paid_height
	local next_payment
	local width
	local linesOfStatsPrinted

	printGraduatedProgressBar 50 0 "Working..."
	cpu=$(printf '%.2f%%' $(echo "scale=4;$(awk '{print $2}' /proc/loadavg)/$(grep -c ^processor /proc/cpuinfo)*100"|bc))
	printGraduatedProgressBar 50 5
	disk=$(df -h)
	printGraduatedProgressBar 50 10
	disk_size=$(awk '/\/$/ {print $2}'<<<"$disk")
	disk_used=$(awk '/\/$/ {print $3}'<<<"$disk")
	disk_free=$(awk '/\/$/ {print $4}'<<<"$disk")

	disk_speed=$(speedTestDisk)
	if [[ -n "$disk_speed" ]];then
		disk_path=${disk_speed%\,*}
		disk_speed=${disk_speed#*\,}
	else
		disk_speed="Not tested"
	fi

	ram=$(free -h)
	printGraduatedProgressBar 50 20
	ram_size=$(awk '/^Mem/ {print $2}'<<<"$ram")
	ram_used=$(awk '/^Mem/ {print $3}'<<<"$ram")
	ram_free=$(awk '/^Mem/ {print $4}'<<<"$ram")

	swap_size=$(awk '/^Swap/ {print $2}'<<<"$ram")
	swap_used=$(awk '/^Swap/ {print $3}'<<<"$ram")
	swap_free=$(awk '/^Swap/ {print $4}'<<<"$ram")

	external_ip=$(curl -4s https://icanhazip.com/)||external_ip=$(curl -4s https://ipecho.net/plain)
	(( $? !=0 || ${#external_ip} < 7 || ${#external_ip} > 15 ))\
	&& external_ip="Error"
	printGraduatedProgressBar 50 25


	port_9999=$(curl -4s https://mnowatch.org/9999/)
	(( ${#port_9999} < 3 || ${#port_9999} > 10 ))\
	&& port_9999="Error"
	printGraduatedProgressBar 50 40

	if [[ "$external_ip" != "Error" ]];then
		curl -4s -d test --connect-timeout 2 ${external_ip}:9999
		(( $? == 52 ))&&local_port_9999="OPEN"||local_port_9999="CLOSED"
	else
		local_port_9999="????"
	fi

	dashd_version=$(sudo -i -u dash bash -c "dashd -version 2>/dev/null" 2>/dev/null)
	(( $? != 0 )) && dashd_version="Not found!"\
	||dashd_version=$(head -1 <<< "$dashd_version")
	printGraduatedProgressBar 50 50

	dashd_procs=$(pidof dashd)
	all_procs=$(ps aux)
	num_dashd_procs=$(awk '{print NF}'<<<"$dashd_procs")
	dashd_pid=()
	dashd_user=()
	((i=0))

	if (( num_dashd_procs > 0 ));then
		for p in $dashd_procs;do
			dashd_pid[$i]=$p
			dashd_user[$i]=$(awk "/$p.*dashd/ {print \$1}"<<<"$all_procs")
			((i++))
		done
	fi
	printGraduatedProgressBar 50 55

	if (( num_dashd_procs > 0 ));then
		block_height=$(sudo -i -u dash bash -c "dash-cli getblockcount 2>/dev/null" 2>/dev/null)
		# Test is for good return, must be a number between 1 and 8 digits long.
		(( $? != 0 )) || [[ ! "$block_height" =~ ^[0-9]+$ ]] ||  ((${#block_height} > 8 || ${#block_height} == 0 )) && block_height="Error"
	else
		block_height="dashd down"
	fi
	printGraduatedProgressBar 50 60


	blockchair_height=$({ curl -s https://api.blockchair.com/dash/stats|jq -r '.data.best_block_height';} 2>/dev/null)
	(( $? != 0 )) || [[ ! "$blockchair_height" =~ ^[0-9]+$ ]] ||  ((${#blockchair_height} > 8 || ${#blockchair_height} == 0 )) && blockchair_height="Error"
	printGraduatedProgressBar 50 65


	cryptoid_height=$(curl -s https://chainz.cryptoid.info/dash/api.dws?q=getblockcount)
	(( $? != 0 )) || [[ ! "$cryptoid_height" =~ ^[0-9]+$ ]] ||  ((${#cryptoid_height} > 8 || ${#cryptoid_height} == 0 )) && cryptoid_height="Error" || ((cryptoid_height++))
	printGraduatedProgressBar 50 75

	if [[ "$blockchair_height" =~ ^[0-9]+$ ]] && (( blockchair_height == cryptoid_height ));then
		[[ "$block_height" != "$blockchair_height" ]] && block_height="!!! $block_height !!!"
	fi


	if (( num_dashd_procs > 0 ));then
		num_peers=$(sudo -i -u dash bash -c "dash-cli getconnectioncount 2>/dev/null" 2>/dev/null)
	else
		num_peers="dashd down"
	fi


	if (( num_dashd_procs > 0 ));then
		masternode_status=$(sudo -i -u dash bash -c "dash-cli masternode status 2>/dev/null|jq -r '.status' 2>/dev/null" 2>/dev/null)
		(( ${#masternode_status} == 0 )) && masternode_status=$(sudo -i -u dash bash -c "dash-cli masternode status 2>&1|tail -1" 2>/dev/null)
	else
		masternode_status="dashd down"
	fi
	printGraduatedProgressBar 50 80

	if (( num_dashd_procs > 0 ));then
		pose_score=$(sudo -i -u dash bash -c "dash-cli masternode status 2>/dev/null|jq -r '.dmnState.PoSePenalty' 2>/dev/null" 2>/dev/null)
		(( $? != 0 )) || [[ ! "$pose_score" =~ ^[0-9]+$ ]] ||  ((${#pose_score} > 8 || ${#pose_score} == 0 )) && pose_score="N/A"
	else
		pose_score="dashd down"
	fi
	printGraduatedProgressBar 50 85


	if (( num_dashd_procs > 0 ));then
		enabled_mns=$(sudo -i -u dash bash -c "dash-cli masternode count 2>/dev/null|jq -r '.enabled' 2>/dev/null" 2>/dev/null)
		(( $? != 0 )) || [[ ! "$enabled_mns" =~ ^[0-9]+$ ]] ||  ((${#enabled_mns} > 8 || ${#enabled_mns} == 0 )) && enabled_mns="Unknown"
	else
		enabled_mns="dashd down"
	fi


	if (( num_dashd_procs > 0 ));then
		mn_sync=$(sudo -i -u dash bash -c "dash-cli mnsync status 2>/dev/null|jq -r '.AssetName' 2>/dev/null" 2>/dev/null)
		(( ${#mn_sync} == 0 )) && mn_sync="Unknown"
	else
		mn_sync="dashd down"
	fi
	printGraduatedProgressBar 50 90

	if (( num_dashd_procs > 0 ));then
		last_paid_height=$(sudo -i -u dash bash -c "dash-cli masternode status 2>/dev/null|jq -r '.dmnState.lastPaidHeight' 2>/dev/null" 2>/dev/null)
		if (( $? != 0 )) || [[ ! "$last_paid_height" =~ ^[0-9]+$ ]] ||  ((${#last_paid_height} > 8 || ${#last_paid_height} == 0 ));then
			next_payment="Unknown"
		else
			if [[ "$enabled_mns" =~ ^[0-9]+$ &&  "$block_height" =~ ^[0-9]+$ ]];then
				next_payment=$((last_paid_height + enabled_mns - block_height))
				next_payment=$(convertBlocksToTime $next_payment)
			else
				next_payment="Unknown"
			fi
		fi
	else
		next_payment="dashd down"
	fi



	printGraduatedProgressBar 50 100

	width=22
	# Now print it all out nicely formatted on screen.
	msg="${bldcyn}$(date)\\n"
	msg+="=====================================================\\n"
	msg+="================== System info ======================\\n"
	msg+="=====================================================\\n"
	echo -e "$msg"

	printf "$bldblu%${width}s : $txtgrn%s\n" "CPU Load" "$cpu"
	printf "$bldblu%${width}s : $txtgrn%s\n" "Disk used / size" "$disk_used / $disk_size"
	printf "$bldblu%${width}s : $txtgrn%s\n" "Disk free" "$disk_free"
	printf "$bldblu%${width}s : $txtgrn%s\n" "Disk speed ($disk_path)" "$disk_speed"
	printf "$bldblu%${width}s : $txtgrn%s\n" "RAM used / size" "$ram_used / $ram_size"
	printf "$bldblu%${width}s : $txtgrn%s\n" "RAM free" "$ram_free"
	printf "$bldblu%${width}s : $txtgrn%s\n" "Swap used / size" "$swap_used / $swap_size"
	printf "$bldblu%${width}s : $txtgrn%s\n" "Swap free" "$swap_free"

	msg="\\n"
	msg+="$bldcyn=====================================================\\n"
	msg+="=================== dashd info ======================\n"
	msg+="=====================================================\\n"
	echo -e "$msg"

	printf "$bldblu%${width}s : $txtgrn%s\n" "dashd version" "$dashd_version"
	printf "$bldblu%${width}s : $txtgrn%s\n" "IP address" "$external_ip"
	printf "$bldblu%${width}s : $txtgrn%s\n" "Port (9999)" "$port_9999"
	printf "$bldblu%${width}s : $txtgrn%s\n" "Local Port (9999)" "$local_port_9999"

	if (( num_dashd_procs == 0 ));then
		printf "$bldblu%${width}s : $txtgrn%s\n" "dashd running?" "No!"
	else
		for ((i=0; i<${#dashd_pid[@]}; i++));do
			printf "$bldblu%${width}s : $txtgrn%s\n" "dashd pid / user" "${dashd_pid[$i]} / ${dashd_user[$i]}"
		done
	fi

	printf "$bldblu%${width}s : $txtgrn%s\n" "Block height" "$block_height"
	printf "$bldblu%${width}s : $txtgrn%s\n" "Blockchair height" "$blockchair_height"
	printf "$bldblu%${width}s : $txtgrn%s\n" "CryptoId height" "$cryptoid_height"
	printf "$bldblu%${width}s : $txtgrn%s\n" "Connected peers" "$num_peers"
	printf "$bldblu%${width}s : $txtgrn%s\n" "Masternode status" "$masternode_status"
	printf "$bldblu%${width}s : $txtgrn%s\n" "PoSe score" "$pose_score"
	printf "$bldblu%${width}s : $txtgrn%s\n" "Masternode sync" "$mn_sync"
	printf "$bldblu%${width}s : $txtgrn%s\n" "Next payment" "$next_payment"
	echo -e "$txtrst"
	linesOfStatsPrinted=33
	if (( num_dashd_procs > 1));then
		((linesOfStatsPrinted=linesOfStatsPrinted + num_dashd_procs -1))
	fi
	return "$linesOfStatsPrinted"
}


# Intelligently display the logfile from the most recent startup.
displayDebugLog(){
	# In order for less to work, we have to restore the file descriptors for stdin and stdout.
	exec 1>&3
	exec 2>&4

	# Sending commands as a here-doc where only the $ needs to be escaped.
	# awk was behaving badly using the -c option on ubuntu, not raspbian.
	sudo -i -u dash bash<<EOF
		[[ -f ~/.dashcore/debug.log ]] || { echo "Could not open debug.log!";exit 1;}
		lineno=\$(grep -n -i Dash\ Core\ version ~/.dashcore/debug.log |tail -1|awk -F ':' '{print \$1}')
		linecount=\$(wc -l ~/.dashcore/debug.log|awk '{print \$1}')
		lines=\$((linecount - lineno +5))
		tail -\${lines} ~/.dashcore/debug.log|less
EOF
	exec 2>&1
}

reclaimFreeDiskSpace(){

	local option
	uninstallJunkPackages
	# Shrink logs.
	sudo journalctl --disk-usage
	sudo journalctl --vacuum-time=2d
	sudo truncate -s0 /var/log/btmp

	msg="\\nThe app cache and the journal logs have been cleaned.\\n"
	msg+="To recover more space, you should reboot your VPS now.\\n"
	msg+="Press ${bldwht}r${txtrst} to reboot now, any other key to return to the menu."
	echo -en "$msg"
	read -r -n1 option
	echo -e "\\n$option">>"$LOGFILE"
	echo
	option=${option:-N}
	[[ $option = [rR] ]] && sudo reboot
}

updateOS(){
	sudo apt update&&sudo apt list --upgradable&&read -p "Press ENTER to continue..."&&sudo apt upgrade&&sudo apt autoremove --purge&&sudo apt clean
}

bootStrap(){

	local remote_user
	local remote_ip
	local option
	local tarfile

	read -r -p "Enter the Dash Admin username of the remote server, eg mno [[mno]] : " remote_user
	echo -e "\\n$remote_user">>"$LOGFILE"
	remote_user=${remote_user:-mno}
	read -r -p "Enter the IP address of the remote server, eg 12.55.65.3 : " remote_ip
	echo -e "\\n$remote_ip">>"$LOGFILE"
	msg="Is there already a tar file on the remote VPS ready to download?\\n"
	msg+="If this is your first time doing this, then just answer no. [y [${bldwht}N${txtrst}]] "
	echo -en "$msg"
	read -r -n1 option
	echo -e "\\n$option">>"$LOGFILE"
	echo
	option=${option:-N}
	if [[ $option = [yY] ]];then
		read -r -p "Paste in the full path of the tar file eg /tmp/dash.tar.bz2 : " tarfile
		echo -e "\\n$tarfile">>"$LOGFILE"
	else
		echo "We are ready to connect to the remote server, when prompted enter the password for it."
		ssh "$remote_user@$remote_ip" <<EOF
		echo "Shutting down dashd on remote server."
		sudo systemctl stop dashd
		echo "Creating tar of the current dashcore directory."
		sudo -i  -u dash bash -c "cd /home/dash;tar cvjf /tmp/dashcore.tar.bz2 .dashcore"
		echo "Tar file is completed, starting dashd again."
		sudo systemctl start dashd
EOF
	fi
	tarfile=${tarfile:-"/tmp/dashcore.tar.bz2"}
	echo "Downloading the tarfile to this server, when promoted, enter the remote user's password."
	scp "$remote_user@$remote_ip:$tarfile" /tmp/
	echo "Extracting tar file to /home/dash"
	sudo -i -u dash bash -c "rm -fr ~/.dashcore;tar xvf /tmp/dashcore.tar.bz2&&cd ~/.dashcore&&yes|rm -fr *.conf se\t* *.pid *.dat *.lock *.log backup/"
	createDashConf
	sudo systemctl stop dashd
	sudo systemctl start dashd
}

getLogo(){
	catimg -h >/dev/null 2>&1 || return 1
	if [[ ! -f /tmp/dash_logo_2018_rgb_for_screens.png ]];then
		wget -q -O /tmp/dash_logo_2018_rgb_for_screens.png https://media.dash.org/wp-content/uploads/dash_logo_2018_rgb_for_screens.png || return 2
	fi
	file /tmp/dash_logo_2018_rgb_for_screens.png 2>/dev/null|grep -q "PNG image data" || return 3
	# By now, we have downloaded and verified a PNG image from the dash.org website and can attempt to render it.
	COLOUR_LOGO=1
}

function printBanner(){
	if [[ -z $COLOUR_LOGO ]];then
		# Gotta escape the back ticks ` with \
		echo -e "$bldwht"\
		"  _____                _____   _    _                      $VERSION\n"\
		" |  __ \      /\      / ____| | |  | |                                    \n"\
		" | |  | |    /  \    | (___   | |__| |                                    \n"\
		" | |  | |   / /\ \    \___ \  |  __  |                                    \n"\
		" | |__| |  / ____ \   ____) | | |  | |                                    \n"\
		" |_____/  /_/    \_\ |_____/  |_|  |_|                                    \n"\
		"  __  __                 _                                       _        \n"\
		" |  \/  |               | |                                     | |       \n"\
		" | \  / |   __ _   ___  | |_    ___   _ __   _ __     ___     __| |   ___ \n"\
		" | |\/| |  / _\` | / __| | __|  / _ \ | '__| | '_ \   / _ \   / _\` |  / _ \ \n"\
		" | |  | | | (_| | \__ \ | |_  |  __/ | |    | | | | | (_) | | (_| | |  __/\n"\
		" |_|  |_|  \__,_| |___/  \__|  \___| |_|    |_| |_|  \___/   \__,_|  \___|\n"\
		"  ______                                                                  \n"\
		" |___  /                                                                  \n"\
		"    / /    ___   _   _   ___                                              \n"\
		"   / /    / _ \ | | | | / __|                                             \n"\
		"  / /__  |  __/ | |_| | \__ \                                             \n"\
		" /_____|  \___|  \__,_| |___/                                             \n$txtrst"
	else
		# In order for catimg to work, we have to restore the file descriptors for stdin and stdout.
		exec 1>&3
		exec 2>&4
		#echo " $VERSION"
		catimg /tmp/dash_logo_2018_rgb_for_screens.png
		exec 2>&1
		if (($(tput cols)>90));then
			msg="  __  __               _                                 _           ____                  \n"
			msg+=" |  \/  |  __ _   ___ | |_   ___   _ _   _ _    ___   __| |  ___    |_  /  ___   _  _   ___\n"
			msg+=" | |\/| | / _\` | (_-< |  _| / -_) | '_| | ' \  / _ \ / _\` | / -_)    / /  / -_) | || | (_-<\n"
			msg+=" |_|  |_| \__,_| /__/  \__| \___| |_|   |_||_| \___/ \__,_| \___|   /___| \___|  \_,_| /__/\n"
		else
			msg="  __  __               _                                 _          \n"
			msg+=" |  \/  |  __ _   ___ | |_   ___   _ _   _ _    ___   __| |  ___   \n"
			msg+=" | |\/| | / _\` | (_-< |  _| / -_) | '_| | ' \  / _ \ / _\` | / -_)\n"
			msg+=" |_|  |_| \__,_| /__/  \__| \___| |_|   |_||_| \___/ \__,_| \___|  \n"
			msg+="\n"
			msg+=" ____                  \n"
			msg+=" |_  /  ___   _  _   ___\n"
			msg+="  / /  / -_) | || | (_-<\n"
			msg+=" /___| \___|  \_,_| /__/\n"
		fi
		echo -e "$msg"
	fi
}


function printRootMenu(){

	msg="\n\n"
	msg+="===============\n"
	msg+="== ROOT MENU ==\n"
	msg+="===============\n"
	msg+="\n\nYou are running as the 'root' user, the only tasks that are necessary to be done\n"
	msg+="as root is to create the user for the administration of the Dash masternode (mno).\n"
	msg+="This script will create the 'mno' user or masternode operator user, this user\n"
	msg+="is a privileged user that can also run commands as root and hence change the system.\n"
	msg+="Later when you log back in as the mno user, the dash user will be created which is what\n"
	msg+="the masternode will run as. The dash user is a unprivileged user and thus\n"
	msg+="cannot make changes to the system. It is important to have these two users separate\n"
	msg+="to improve the security of your masternode, after all you don't want your masternode\n"
	msg+="to get hacked and end up mining Monero and becoming unstable!\n\n"
	msg+="The first option will check to see if the mno user already exists on your system before\n"
	msg+="making changes.\n\n"
	msg+="\n\nMake a selection from the below options.\n"
	msg+="1. Create mno user for a new masternode server.\n"
	msg+="9. Quit.\n\n"

	echo -e "$msg"
}


function rootMenu(){

	local option
	while :
	do
		echo -en "Choose option [1 [${bldwht}9${txtrst}]]: "
		read -r -n1 option
		echo -e "\n$option">>"$LOGFILE"
		echo
		option=${option:-9}
		case $option in
			1)
				createMnoUser
				return 0
				;;
			9)
				echo "Exiting..."
				return 9
				;;
			*)
				echo "Invalid selection, please enter again."
				busyLoop24bit 5000 300 800
				return 0
				;;
		esac
	done

}

manageMasternodeMenu(){

	local option
	msg="\n\n"
	msg+="=====================\n"
	msg+="== MASTERNODE MENU ==\n"
	msg+="=====================\n"
	msg+="\n\nMake a selection from the below options.\n"
	msg+="1. (Re)install dash binaries, use this for updates.\n"
	msg+="2. Review and edit your dash.conf file.\n"
	msg+="3. Reindex dashd.\n"
	msg+="4. View debug.log.\n"
	msg+="9. Return to Main Menu.\n"
	echo -e "$msg"
	echo -en "Choose option [1 2 3 4 5 [${bldwht}9$txtrst]]: "
	read -r -n1 option
	echo -e "\n$option">>"$LOGFILE"
	echo
	option=${option:-9}
	case $option in
		1)
			msg="This will re-install your dash binaries.  Use this option if you wish to\n"
			msg+="update the dash daemon, the dashd service will be automatically restarted\n"
			msg+="after the update.\n\n"
			msg+="Press Y to continue or another other key to return to the main menu [y [${bldwht}N${txtrst}]] "
			echo -en "$msg"
			read -r -n1 option
			echo -e "\n$option">>"$LOGFILE"
			option=${option:-N}
			[[ $option = [yY] ]] || return 0
			echo
			addKeyToStore &&\
			downloadDashd || { echo "Download of dashd has failed, exiting.";exit 1;}
			filename=$(</tmp/.filename)
			verifyDashd "$filename" &&\
			installDashd "$filename"
			if (( $? == 0 ));then
				echo "Installation has been successful, restarting the dashd daemon..."
				sudo systemctl stop dashd
				sudo systemctl start dashd
				changePermsDebugLog
			else
				echo "Installation of dashd has been unsuccessful, please investigate or seek support!"
			fi
			read -r -s -n1 -p "Press any key to continue. "
			echo
			return 0
			;;
		2)
			echo "******************** $DASH_CONF ********************"
			sudo cat "$DASH_CONF"
			echo "******************** $DASH_CONF ********************"
			msg="\nAbove is your existing dash.conf, if you wish to edit it press Y any other key will\n"
			msg+="return to the main menu. [y [${bldwht}N${txtrst}]] "
			echo -en "$msg"
			read -r -n1 option
			echo -e "\n$option">>"$LOGFILE"
			option=${option:-N}
			[[ $option = [yY] ]] || return 0
			echo
			editDashConf
			sudo systemctl stop dashd
			sudo systemctl start dashd
			changePermsDebugLog
			read -r -s -n1 -p "Done!  Press any key to continue. "
			echo
			return 0
			;;
		3)
			msg="As a last resort if your node is stuck, you can choose to reindex it.\n"
			msg+="This process will take about 3 hours depending on your hardware.\n"
			msg+="You can monitor the progress from the status page...\n"
			msg+="Press Y to proceed, or any other key to return to the main menu [y [${bldwht}N${txtrst}]] "
			echo -en "$msg"
			read -r -n1 option
			echo -e "\n$option">>"$LOGFILE"
			option=${option:-N}
			[[ $option = [yY] ]] || return 0
			echo
			sudo systemctl stop dashd
			sudo -i -u dash bash -c "dashd -reindex"
			read -r -s -n1 -p "Reindex has started!  Press any key to continue. "
			echo
			return 0
			;;
		4)
			msg="This option will open the debug.log file in less from when the node\n"
			msg+="was last started. To navigate the log file use the below hints.\n"
			msg+="G - Pressing uppercase G will take you to the end of the log file to see the most recent entries.\n"
			msg+="g - Pressing lowercase g takes you to the start (oldest entries).\n"
			msg+="q - To quit.\n"
			msg+="/ - Typing / and search term will search the file for that term.\n"
			msg+="n - When in search mode n will skip to the next occurrence of the term.\n"
			msg+="b - When in search mode b will go back to the previous occurrence of the term.\n"
			msg+="Press Y to proceed, or any other key to return to the main menu [y [${bldwht}N${txtrst}]] "
			echo -en "$msg"
			read -r -n1 option
			echo -e "\n$option">>"$LOGFILE"
			option=${option:-N}
			[[ $option = [yY] ]] || return 0
			echo
			changePermsDebugLog
			displayDebugLog
			read -r -s -n1 -p "Press any key to continue. "
			echo
			return 0
			;;
		9)
			echo "Back to Main Menu..."
			return 9
			;;
		*)
			echo "Invalid selection, please enter again."
			busyLoop24bit 5000 300 800
			return 0
			;;
	esac
}

function printMainMenu(){

	msg="\n\n"
	msg+="===============\n"
	msg+="== MAIN MENU ==\n"
	msg+="===============\n"
	msg+="\n\nMake a selection from the below options.\n"
	msg+="1. Install and configure a new DASH Masternode.\n"
	msg+="2. Check system status.\n"
	msg+="3. Manage your masternode.\n"
	msg+="4. Reclaim free disk space.\n"
	msg+="5. Update the OS (recommended).\n"
	msg+="6. Bootstrap this server from another VPS running a fully synced DASH Masternode.\n"
	msg+="9. Quit.\n"
	echo -e "$msg"
}


function mainMenu (){
	local option
	local scroll_back_lines
	while :
	do
		echo -en "Choose option [1 2 3 4 5 [${bldwht}9$txtrst]]: "
		read -r -n1 option
		echo -e "\n$option">>"$LOGFILE"
		echo
		option=${option:-9}
		case $option in
			1)
				installMasternode
				return 0
				;;
			2)
				option='r'
				while [[ "$option" = 'R' || "$option" = 'r' ]];do
					showStatus
					scroll_back_lines=$?
					((scroll_back_lines++))
					echo -en "Press $bldwht""R""$txtrst to check status again or any other key to return to main menu. "
					read -r -n1 option
					option=${option:-N}
					[[ $option = [rR] ]] && echo -e "\e[${scroll_back_lines}A\e[73D"
				done
				echo
				return 0
				;;
			3)
				while manageMasternodeMenu;do : ;done
				return 0
				;;
			4)
				reclaimFreeDiskSpace
				return 0
				;;
			5)
				updateOS
				read -r -s -n1 -p "Press any key to continue. "
				return 0
				;;
			6)
				msg="This option will allow you to bootstrap this masternode with blockchain\n"
				msg+="data from another masternode.  This can make syncing a lot faster.\n"
				msg+="Press Y to proceed, or any other key to return to the main menu [y [${bldwht}N${txtrst}]] "
				echo -en "$msg"
				read -r -n1 option
				echo -e "\n$option">>"$LOGFILE"
				option=${option:-N}
				[[ $option = [yY] ]] || return 0
				echo
				bootStrap
				read -r -s -n1 -p "Bootstrap is complete.  Press any key to continue. "
				echo
				return 0
				;;
			9)
				echo "Exiting..."
				return 9
				;;
			*)
				echo "Invalid selection, please enter again."
				busyLoop24bit 5000 300 800
				return 0
				;;
		esac
	done
}


##############################################################
#
#	Main
#
##############################################################
VERSION="v1.4.7 20240204"
LOGFILE="$(pwd)/$(basename "$0").log"
ZEUS="$0"
MNO_USER=mno
# dashd install location.
INSTALL_LOCATION="/opt"
DASH_CONF="/home/dash/.dashcore/dash.conf"

# I need to save the file descriptor for stderr since without a
# working stderr nano doesn't work correctly.
exec 3>&1
exec 4>&2
{
	echo -e "$ZEUS\t$VERSION"
	getLogo
	osCheck
	OS=$?;export OS
	(( OS > 1 )) && exit $OS
	idCheck
	idcheckretval=$?
	retval=0
	while (( retval != 9 ))
	do
		printBanner
		if (( idcheckretval == 0 ))
		then
			printMainMenu
			mainMenu
		elif (( idcheckretval == 1 ))
		then
			printRootMenu
			rootMenu
		else
			msg="Your sudo does not seem to be working, either you entered the wrong password\n"
			msg+="or this user lacks sudo privileges.  You can try again, or try running this\n"
			msg+="program under another account, for example root."
			echo -e "$msg"
			break
		fi
		retval=$?
	done
} 2>&1 |tee -a "$LOGFILE"
