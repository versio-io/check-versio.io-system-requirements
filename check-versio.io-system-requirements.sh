#!/bin/sh
# set -e

echo "                    _             _        "
echo "__   _____ _ __ ___(_) ___       (_) ___   "
echo "\ \ / / _ \ '__/ __| |/ _ \      | |/ _ \  "
echo " \ V /  __/ |  \__ \ | (_) |  _  | | (_) | "
echo "  \_/ \___|_|  |___/_|\___/  (_) |_|\___/  "
echo "                                           "
echo ""
echo "QMETHODS - Business & IT Consulting GmbH"
echo "Copyright (C) | All rights reserved."
echo "-----------------------------------------------"
echo ""

echo -e "\n[versio.io] Check Versio.io system requirements"
echo "==============================================="
export ERROR=0
export WARNING=0
export WGET=0
export CURL=0

if [ "$EUID" -ne 0 ];  then 
	echo -e "\033[41mPlease run the script as a root user.\033[0m"
	echo ""
	exit 1;
fi
echo ""

# ==================================================================
# Verify operating system
# ==================================================================
echo -e "\n[versio.io] Check operating system support"
WHICH_OS=$(cat /etc/*release | grep ^NAME)
if [ "$WHICH_OS" = "NAME=\"Fedora Linux\"" ]; then
     echo -e "\t\033[42mSupported operating system.\033[0m"
     echo -e "\tOS: Fedora"
elif [ "$WHICH_OS" = "NAME=\"Ubuntu\"" ]; then
	echo -e "\t\033[42mSupported operating system.\033[0m"
	echo -e "\tOS: Ubuntu"
elif [ "$WHICH_OS" = "NAME=\"Red Hat Enterprise Linux Server\"" ]; then
	echo -e "\t\033[42mSupported operating system.\033[0m"
	echo -e "\tOS: Red Hat Enterprise Linux"
elif [ "$WHICH_OS" = "NAME=\"Debian GNU/Linux\"" ]; then
	echo -e "\t\033[42mSupported operating system.\033[0m"
	echo -e "\tOS: Debian"
else
    echo -e "\t\033[30m\033[43mUnsupported operating system.\033[0m"  
    echo -e "\tLinux expertise is necessary to run the Versio.io platform"  
	echo -e "\tOS: $WHICH_OS"
	export WARNING=1
fi

# ==================================================================
# Verify operating system
# ==================================================================
echo -e "\n[versio.io] Check IPv6 support"
IPV6=$(cat /sys/module/ipv6/parameters/disable)
if [ "$IPV6" = "0" ]; then
     echo -e "\t\033[42mIPv6 supported available.\033[0m"
else
    echo -e "\t\033[30m\033[43mIPv6 support unavailable.\033[0m"  
    echo -e "\tPlease activate IPv6 support!"  
	export WARNING=1
fi

# ============================================
# Verify OS commands available
# ============================================
echo -e "\n[versio.io] Check if the required commands for installation are available"
for command in \
		tar \
		gzip \
		wget \
		openssl \
		grep \
		curl \
		ss \
		which \
		systemctl \
		pv
do
	echo -e "\tCheck command '$command':"
	IS_INSTALLED=$(which $command 2>/dev/null| wc -l)
	if [ "$IS_INSTALLED" = "1" ]; then
		echo -e "\t\t\033[42mAvailable.\033[0m"
		if [ "$command" = "curl" ]; then 
			export CURL=1
		elif [ "$command" = "wget" ]; then 
			export WGET=1
		fi
	else
		echo -e "\t\t\033[41mNot installed\033[0m"  
		echo -e "\t\tPlease install app (apt/yum install '$command)"  
		export ERROR=1
	fi
done


# ============================================
# Verify docker is installed
# ============================================
echo -e "\n[versio.io] Check if docker installation is available"
IS_DOCKER_INSTALLED=$(which docker 2> /dev/null | grep -c "docker")
if [ "$IS_DOCKER_INSTALLED" = "1" ]; then
	echo -e "\t\033[42mAvailable\033[0m"
	echo -e "\t"$(docker --version)
else
    echo -e "\t\033[41mNot installed\033[0m"  
	export ERROR=1
fi


# ============================================
# Verify docker daemon is running
# ============================================
echo -e "\n[versio.io] Check if docker daemon is not running"
IS_DOCKER_DAEMON_RUNNING=$(systemctl status docker 2> /dev/null | grep "Active: active (running)" | wc -l)
if [ "$IS_DOCKER_DAEMON_RUNNING" = "1" ]; then
	echo -e "\t\033[42mRunning\033[0m"
else
    echo -e "\t\033[41mNot runningd\033[0m"  
	echo -e "\tTry to start with: systemctl start docker"  
	export ERROR=1
fi


# ============================================
# Verify docker-compose is installed
# ============================================
echo -e "\n[versio.io] Check if docker composed installation is available"
IS_DOCKER_COMPOSER_INSTALLED=$(which docker-compose 2> /dev/null | grep -c "docker-compose")
if [ "$IS_DOCKER_COMPOSER_INSTALLED" = "1" ]; then
	echo -e "\t\033[42mAvailable\033[0m"
	echo -e "\t"$(docker-compose --version)
else
    echo -e "\t\033[41mNot installed\033[0m"  
	export ERROR=1
fi

# ============================================
# Verify that no anti virus program or other blocker are running
# ============================================
# McAfee: ds_agent,ds_am, dsvp
echo -e "\n[versio.io] Check if a McAfee virus app is running"
for app in \
	ds-agent \
	ds-am, \
	dsvp
do
	echo -e "\tApplication: $app"
	IS_AGENT_DETECTED=$(ps -ef | grep -c $app)
	if [ "$IS_AGENT_DETECTED" = "1" ]; then
		echo -e "\t\t\033[42mNo virus app is running\033[0m"
	else
    	echo -e "\t\t\033[30m\033[43mVirus app is running\033[0m"  
    	echo -e "\t\tVirus can affect the functionality of Versio.io "  
		export WARNING=1
	fi
done

# ============================================
# Verify that port 80 and port 443 are not used (blocked)
# ============================================
echo -e "\n[versio.io] Check if needed ports are not used"
echo -e "\tPort 80 (HTTP)"
IS_USED=$(ss -lntu  | grep -c ":80")
if [ "$IS_USED" = "0" ]; then 
	echo -e "\t\t\033[42mNot used\033[0m"
else
    echo -e "\t\t\033[41mPort is in use\033[0m"  
    echo -e "\t\tPlease stop the process that use port 80"  
	export ERROR=1
fi
echo -e "\tPort 443 (HTTPS)"
IS_USED=$(ss -lntu | grep -c ":443")
if [ "$IS_USED" = "0" ]; then
	echo -e "\t\t\033[42mNot used\033[0m"
else
    echo -e "\t\t\033[41mPort is in use\033[0m"  
    echo -e "\t\tPlease stop the process that use port 443"  
	export ERROR=1
fi

# ============================================
# Verify external URLs are reachable
# ============================================
echo -e "\n[versio.io] Check if network connection to Versio.io online services are available"
for domain in \
	https://live.versio.io \
	https://api.versio.io/gov/1.0/vendors \
	https://repository.versio.io
do
	if [ "$WGET" = "1" ]; then
		echo -e "\tCheck network connection to '$domain' with wget."
		PING_RESULT=$(wget -q -O -S --spider $domain | echo $?)
		if [ "$PING_RESULT" = "0" ]; then
			echo -e "\t\t\033[42mAvailable.\033[0m"
		else
			echo -e "\t\t\033[30m\033[43mNot available.\033[0m"
			echo -e "\t\tOnly restricted service available."
			WARNING=1
		fi
	elif [ "$CURL" = "1" ]; then
		echo -e "\tCheck network connection to '$domain' with curl."
		PING_RESULT=$(curl -Is $domain | head -n 1 | grep -e 200 -e 401 | wc -l)
		if [ "$PING_RESULT" = "1" ]; then
			echo -e "\t\t\033[42mAvailable.\033[0m"
		else
			echo -e "\t\t\033[30m\033[43mNot available.\033[0m"
			echo -e "\t\tOnly restricted service available."
			WARNING=1
		fi
	else
		echo -e "\tCheck network connection to '$domain'."
		echo -e "\t\t\033[30m\033[43mNo command to check URL connection available.\033[0m"
	fi
done



# =================================================
# Verify hardware vendor warranty API are reachable
# =================================================
echo -e "\n[versio.io] Check if warranty APIs of hardware vendors are available"
for domain in \
	https://apigtwb2c.us.dell.com \
	https://supporttickets.intel.com \
	http://supportapi.lenovo.com
do
	if [ "$WGET" = "1" ]; then
		echo -e "\tCheck network connection to '$domain' with wget."
		PING_RESULT=$(wget -q -O -S --spider $domain | echo $?)
		if [ "$PING_RESULT" = "0" ]; then
			echo -e "\t\t\033[42mAvailable.\033[0m"
		else
			echo -e "\t\t\033[30m\033[43mNot available.\033[0m"
			echo -e "\t\tWarranty information for servers, workstations and laptops cannot be determined."
			WARNING=1
		fi
	elif [ "$CURL" = "1" ]; then
		echo -e "\tCheck network connection to '$domain' with curl."
		PING_RESULT=$(curl -Is $domain | head -n 1 | grep -e 200 -e 401 | wc -l)
		if [ "$PING_RESULT" = "1" ]; then
			echo -e "\t\t\033[42mAvailable.\033[0m"
		else
			echo -e "\t\t\033[30m\033[43mNot available.\033[0m"
			echo -e "\t\tWarranty information for servers, workstations and laptops cannot be determined."
			WARNING=1
		fi
	else
		echo -e "\tCheck network connection to '$domain'."
		echo -e "\t\t\033[30m\033[43mNo command to check vendor warranty API connection available.\033[0m"
	fi
done


# ============================================
# Final result
# ============================================
echo -e "\n[versio.io] System requirements verification result"
if [ "$WARNING" = "1" ]; then
	echo -e "\t\033[30m\033[43mThere are active warning!\033[0m"
    echo -e "\tYou must have the knowledge to handle it."
fi
if [ "$ERROR" = "0" ]; then
	echo -e "\t\033[42mSystem requirements are fulfilled. You are ready to install and start Versio.io Managed plattform!\033[0m"
    echo -e "\tYou are ready to customize configuration and start Versio.io platform. See manual at https://doc.versio.io/setup-managed"
	echo ""
else
    echo -e "\t\033[41mSystem requirements are not fulfilled to install Versio.io Managed platform.\033[0m"  
    echo -e "\tPlease read more about system requirements in Versio.io manual at https://doc.versio.io/setup-system-requirements"
	echo ""
	exit 1;
fi

exit 0;